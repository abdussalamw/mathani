import os
import subprocess
import sys

def run_command(command):
    print(f"Running: {command}")
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    for line in process.stdout:
        print(line.decode().strip())
    process.wait()
    return process.returncode

def main():
    model_id = "FaisaI/tadabur-Whisper-Small"
    output_dir = "onnx_model"
    
    print(f"--- Starting conversion for {model_id} ---")
    
    # 1. Export to ONNX using Optimum
    # We use --trust-remote-code just in case
    export_cmd = f"optimum-cli export onnx --model {model_id} --task automatic-speech-recognition --library transformers {output_dir}"
    
    res = run_command(export_cmd)
    if res != 0:
        print("Error during export!")
        return

    print(f"Model exported to {output_dir}")
    
    # 2. List files
    print("Files in output directory:")
    if os.path.exists(output_dir):
        for f in os.listdir(output_dir):
            size = os.path.getsize(os.path.join(output_dir, f)) / (1024 * 1024)
            print(f" - {f} ({size:.2f} MB)")
    else:
        print("Output directory not found!")

if __name__ == "__main__":
    main()
