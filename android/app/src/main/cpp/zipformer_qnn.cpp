#define ORT_API_MANUAL_INIT
#include "onnxruntime_cxx_api.h"

#include <dlfcn.h>
#include <jni.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <memory>
#include <stdexcept>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace {

constexpr char kProvider[] = "QNNExecutionProvider";
constexpr size_t kTensorCount = 99;
constexpr size_t kFeatureSize = 61 * 80;
constexpr size_t kLogitsSize = 12 * 251;

void Require(bool condition, const char* message) {
  if (!condition) throw std::runtime_error(message);
}

class Runtime {
 public:
  static Runtime& Get(const std::string& library_dir) {
    static Runtime runtime(library_dir);
    return runtime;
  }

  Ort::Env& Env() { return environment_; }

 private:
  explicit Runtime(const std::string& library_dir)
      : library_(dlopen((library_dir + "/libmathani_ort.so").c_str(),
                        RTLD_NOW | RTLD_LOCAL), &dlclose) {
    // Use the exact isolated runtime handle so Sherpa's existing ORT remains
    // independent even if that library has already been mapped in this process.
    Require(library_ != nullptr, "Could not load the isolated ORT runtime");
    const auto get_api = reinterpret_cast<decltype(&OrtGetApiBase)>(
        dlsym(library_.get(), "OrtGetApiBase"));
    Require(get_api != nullptr, "ORT entry point missing");
    const auto* base = get_api();
    Require(std::string_view(base->GetVersionString()) == "1.29.0", "ORT version mismatch");
    const auto* api = base->GetApi(ORT_API_VERSION);
    Require(api != nullptr, "ORT ABI mismatch");
    Ort::InitApi(api);
    environment_ = Ort::Env(ORT_LOGGING_LEVEL_WARNING, "MathaniZipformer");
    environment_.DisableTelemetryEvents();
    environment_.RegisterExecutionProviderLibrary(
        kProvider, (library_dir + "/libonnxruntime_providers_qnn.so").c_str());
  }

  // Members release in reverse order, so ORT objects never outlive its library.
  std::unique_ptr<void, decltype(&dlclose)> library_;
  Ort::Env environment_{nullptr};
};

struct TensorSpec {
  std::string name;
  std::vector<int64_t> shape;
  ONNXTensorElementDataType type;
};

std::vector<TensorSpec> Inspect(Ort::Session& session, bool input) {
  const auto count = input ? session.GetInputCount() : session.GetOutputCount();
  Require(count == kTensorCount, "Zipformer tensor count mismatch");
  Ort::AllocatorWithDefaultOptions allocator;
  std::vector<TensorSpec> specs;
  specs.reserve(count);
  for (size_t i = 0; i < count; ++i) {
    const auto name = input ? session.GetInputNameAllocated(i, allocator)
                            : session.GetOutputNameAllocated(i, allocator);
    const auto value = input ? session.GetInputTypeInfo(i) : session.GetOutputTypeInfo(i);
    const auto tensor = value.GetTensorTypeAndShapeInfo();
    auto shape = tensor.GetShape();
    Require(!shape.empty() && std::all_of(shape.begin(), shape.end(),
        [](int64_t size) { return size > 0; }) && tensor.GetElementCount() <= 1048576,
        "Zipformer state must have a bounded static shape");
    specs.push_back({name.get(), std::move(shape), tensor.GetElementType()});
  }
  return specs;
}

bool Is(const TensorSpec& spec, ONNXTensorElementDataType type, const std::vector<int64_t>& shape) {
  return spec.type == type && spec.shape == shape;
}

class Stream {
 public:
  Stream(const std::string& model_path, const std::string& library_dir)
      : session_(Open(model_path, library_dir)),
        inputs_(Inspect(session_, true)), outputs_(Inspect(session_, false)) {
    std::unordered_map<std::string, size_t> output_indices;
    for (size_t i = 0; i < outputs_.size(); ++i) {
      const auto& output = outputs_[i];
      output_names_.push_back(output.name.c_str());
      Require(output_indices.emplace(output.name, i).second, "Duplicate output");
    }
    logits_index_ = output_indices.at("log_probs");
    Require(Is(outputs_[logits_index_], ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, {1, 12, 251}),
            "Zipformer logits shape mismatch");
    processed_index_ = output_indices.at("new_processed_lens");
    Require(Is(outputs_[processed_index_], ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64, {1}),
            "Zipformer frame count shape mismatch");

    for (size_t i = 0; i < inputs_.size(); ++i) {
      const auto& input = inputs_[i];
      input_names_.push_back(input.name.c_str());
      if (input.name == "x") {
        Require(feature_index_ == kTensorCount &&
                Is(input, ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, {1, 61, 80}),
                "Zipformer audio feature shape mismatch");
        feature_index_ = i;
        next_.push_back(kTensorCount);
      } else {
        const size_t next = output_indices.at("new_" + input.name);
        Require(Is(outputs_[next], input.type, input.shape) &&
                (input.name == "processed_lens" || input.type == ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT),
                "Zipformer stream state mismatch");
        next_.push_back(next);
      }
    }
    Require(feature_index_ < kTensorCount, "Zipformer audio input missing");
    Reset();
  }

  Stream(const Stream&) = delete;
  Stream& operator=(const Stream&) = delete;

  void Reset() {
    Ort::AllocatorWithDefaultOptions allocator;
    std::vector<Ort::Value> zero;
    zero.reserve(kTensorCount);
    for (const auto& input : inputs_) {
      auto value = Ort::Value::CreateTensor(allocator, input.shape.data(), input.shape.size(), input.type);
      const auto length = value.GetTensorTypeAndShapeInfo().GetElementCount();
      if (input.type == ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT) {
        std::fill_n(value.GetTensorMutableData<float>(), length, 0.0F);
      } else {
        Require(input.type == ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64, "Zipformer state type mismatch");
        std::fill_n(value.GetTensorMutableData<int64_t>(), length, int64_t{0});
      }
      zero.push_back(std::move(value));
    }
    state_.swap(zero);
    processed_ = 0;
  }

  void Run(JNIEnv* jni, jfloatArray features, jfloatArray logits) {
    Require(features != nullptr && jni->GetArrayLength(features) == kFeatureSize &&
            logits != nullptr && jni->GetArrayLength(logits) == kLogitsSize,
            "Zipformer array size mismatch");
    auto* audio = state_[feature_index_].GetTensorMutableData<float>();
    jni->GetFloatArrayRegion(features, 0, kFeatureSize, audio);
    if (jni->ExceptionCheck()) return;
    Require(std::all_of(audio, audio + kFeatureSize, [](float v) { return std::isfinite(v); }),
            "Invalid audio features");
    auto outputs = session_.Run(Ort::RunOptions{nullptr}, input_names_.data(), state_.data(),
                                state_.size(), output_names_.data(), output_names_.size());
    const auto* output = outputs[logits_index_].GetTensorData<float>();
    Require(std::all_of(output, output + kLogitsSize, [](float v) { return std::isfinite(v); }),
            "Non-finite logits");
    const int64_t next = *outputs[processed_index_].GetTensorData<int64_t>();
    Require(next == processed_ + 24, "Zipformer frame count did not advance");
    jni->SetFloatArrayRegion(logits, 0, kLogitsSize, output);
    if (jni->ExceptionCheck()) return;
    // Reuse ORT-owned state buffers, moving each result without a JNI round trip.
    for (size_t i = 0; i < next_.size(); ++i) {
      if (next_[i] != kTensorCount) state_[i] = std::move(outputs[next_[i]]);
    }
    processed_ = next;
  }

 private:
  static Ort::Session Open(const std::string& model_path, const std::string& library_dir) {
    auto& env = Runtime::Get(library_dir).Env();
    std::vector<Ort::ConstEpDevice> devices;
    for (const auto& device : env.GetEpDevices()) {
      if (std::string_view(device.EpName()) == kProvider &&
          device.Device().Type() == OrtHardwareDeviceType_NPU) {
        devices.push_back(device);
        break;
      }
    }
    Require(!devices.empty(), "QNN NPU device unavailable");
    Ort::SessionOptions options;
    options.AddConfigEntry("session.disable_cpu_ep_fallback", "1");
    options.AppendExecutionProvider_V2(env, devices, {
        {"backend_path", library_dir + "/libQnnHtp.so"},
        {"soc_model", "SM8650"},
        {"htp_arch", "75"},
        {"offload_graph_io_quantization", "0"},
    });
    return Ort::Session(env, model_path.c_str(), options);
  }

  Ort::Session session_;
  const std::vector<TensorSpec> inputs_;
  const std::vector<TensorSpec> outputs_;
  std::vector<const char*> input_names_;
  std::vector<const char*> output_names_;
  std::vector<size_t> next_;
  std::vector<Ort::Value> state_;
  size_t feature_index_ = kTensorCount;
  size_t logits_index_ = kTensorCount;
  size_t processed_index_ = kTensorCount;
  int64_t processed_ = 0;
};

std::string UtfString(JNIEnv* jni, jstring value) {
  Require(value != nullptr, "Missing model or library path");
  const char* chars = jni->GetStringUTFChars(value, nullptr);
  Require(chars != nullptr, "Unable to read path");
  try {
    std::string string(chars);
    jni->ReleaseStringUTFChars(value, chars);
    return string;
  } catch (...) {
    jni->ReleaseStringUTFChars(value, chars);
    throw;
  }
}

void ReportFailure(JNIEnv* jni, const char* message) {
  if (jni->ExceptionCheck()) return;
  jclass clazz = jni->FindClass("java/lang/IllegalStateException");
  if (clazz != nullptr) jni->ThrowNew(clazz, message);
}

Stream* FromHandle(jlong handle) {
  return reinterpret_cast<Stream*>(static_cast<intptr_t>(handle));
}

}  // namespace

extern "C" JNIEXPORT jlong JNICALL Java_com_example_mathani_ZipformerQnn_open(
    JNIEnv* jni, jobject, jstring model, jstring library_dir) {
  try {
    auto stream = std::make_unique<Stream>(UtfString(jni, model), UtfString(jni, library_dir));
    return static_cast<jlong>(reinterpret_cast<intptr_t>(stream.release()));
  } catch (...) {
    ReportFailure(jni, "QNN session initialization failed");
    return 0;
  }
}

extern "C" JNIEXPORT void JNICALL Java_com_example_mathani_ZipformerQnn_run(
    JNIEnv* jni, jobject, jlong handle, jfloatArray features, jfloatArray logits) {
  try {
    Require(handle != 0, "Missing QNN session");
    FromHandle(handle)->Run(jni, features, logits);
  } catch (...) {
    ReportFailure(jni, "QNN frame inference failed");
  }
}

extern "C" JNIEXPORT void JNICALL Java_com_example_mathani_ZipformerQnn_reset(
    JNIEnv* jni, jobject, jlong handle) {
  try {
    Require(handle != 0, "Missing QNN session");
    FromHandle(handle)->Reset();
  } catch (...) {
    ReportFailure(jni, "QNN state reset failed");
  }
}

extern "C" JNIEXPORT void JNICALL Java_com_example_mathani_ZipformerQnn_close(
    JNIEnv*, jobject, jlong handle) {
  delete FromHandle(handle);
}
