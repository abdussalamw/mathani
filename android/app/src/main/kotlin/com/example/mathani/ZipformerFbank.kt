package com.example.mathani

import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.ln
import kotlin.math.pow
import kotlin.math.sin

/** Extracts the Kaldi log-Mel features expected by Zipformer V3 from normalized 16 kHz PCM. */
internal class ZipformerFbank {
    private val pcm = FloatArray(FRAME_SAMPLES)
    private val frame = FloatArray(FRAME_SAMPLES)
    private val real = FloatArray(FFT_SIZE)
    private val imaginary = FloatArray(FFT_SIZE)
    private val power = FloatArray(FFT_SIZE / 2)
    private val features = FloatArray(WINDOW_FRAMES * MEL_BINS)
    private var writeIndex = 0
    private var samplesSeen = 0L
    private var nextFrameStart = FIRST_FRAME_START.toLong()
    private var framesInWindow = 0
    private var finished = false

    fun accept(samples: FloatArray, onWindow: (FloatArray) -> Unit) {
        check(!finished) { "Feature stream is finished" }
        require(samples.all { it.isFinite() }) { "PCM contains a non-finite sample" }
        for (sample in samples) {
            appendSample(sample, onWindow)
        }
    }

    fun finish(onWindow: (FloatArray) -> Unit) {
        check(!finished) { "Feature stream is finished" }
        finished = true
        // The tail gives the decoder right context. It is not recorded as microphone input.
        repeat(DECODER_TAIL_SAMPLES) { appendSample(0f, onWindow) }

        val finalFrameCount = (samplesSeen + FRAME_SHIFT / 2) / FRAME_SHIFT
        val finalFrameLimit = FIRST_FRAME_START + finalFrameCount * FRAME_SHIFT
        while (nextFrameStart < finalFrameLimit) {
            appendFrame(onWindow)
        }
    }

    private fun appendSample(sample: Float, onWindow: (FloatArray) -> Unit) {
        pcm[writeIndex] = sample
        writeIndex = if (writeIndex + 1 == pcm.size) 0 else writeIndex + 1
        samplesSeen++
        if (nextFrameStart + FRAME_SAMPLES == samplesSeen) {
            appendFrame(onWindow)
        }
    }

    private fun appendFrame(onWindow: (FloatArray) -> Unit) {
        var sum = 0f
        for (index in frame.indices) {
            val source = nextFrameStart + index
            // With snip_edges=false, Kaldi reflects samples around the edges of the stream.
            val reflected = when {
                source < 0L -> -source - 1L
                source >= samplesSeen -> 2L * samplesSeen - 1L - source
                else -> source
            }
            val sample = pcm[(reflected % pcm.size).toInt()]
            frame[index] = sample
            sum += sample
        }
        val mean = sum / FRAME_SAMPLES
        var previous = frame[0] - mean
        for (index in frame.indices) {
            val sample = frame[index] - mean
            real[FFT_REVERSED[index]] = (sample - PREEMPHASIS * previous) * POVEY_WINDOW[index]
            previous = sample
        }
        for (index in FRAME_SAMPLES until FFT_SIZE) {
            real[FFT_REVERSED[index]] = 0f
        }
        imaginary.fill(0f)
        fft()

        for (index in power.indices) {
            power[index] = real[index] * real[index] + imaginary[index] * imaginary[index]
        }
        val destination = framesInWindow * MEL_BINS
        for ((bin, filter) in MEL_FILTERS.withIndex()) {
            var energy = 0f
            for (index in filter.weights.indices) {
                energy += filter.weights[index] * power[filter.startBin + index]
            }
            features[destination + bin] = ln(maxOf(energy, FLOAT_EPSILON))
        }

        nextFrameStart += FRAME_SHIFT
        framesInWindow++
        if (framesInWindow == WINDOW_FRAMES) {
            val window = features.copyOf()
            features.copyInto(features, startIndex = WINDOW_SHIFT_FRAMES * MEL_BINS)
            framesInWindow -= WINDOW_SHIFT_FRAMES
            onWindow(window)
        }
    }

    // Iterative radix-2 FFT, with the real input already placed in bit-reversed order.
    private fun fft() {
        var stageSize = 2
        while (stageSize <= FFT_SIZE) {
            val half = stageSize / 2
            val stride = FFT_SIZE / stageSize
            for (start in 0 until FFT_SIZE step stageSize) {
                for (offset in 0 until half) {
                    val left = start + offset
                    val right = left + half
                    val twiddle = offset * stride
                    val evenReal = real[left]
                    val evenImaginary = imaginary[left]
                    val oddReal = real[right] * FFT_COS[twiddle] - imaginary[right] * FFT_SIN[twiddle]
                    val oddImaginary = real[right] * FFT_SIN[twiddle] + imaginary[right] * FFT_COS[twiddle]
                    real[left] = evenReal + oddReal
                    imaginary[left] = evenImaginary + oddImaginary
                    real[right] = evenReal - oddReal
                    imaginary[right] = evenImaginary - oddImaginary
                }
            }
            stageSize *= 2
        }
    }

    private data class MelFilter(val startBin: Int, val weights: FloatArray)

    private companion object {
        const val SAMPLE_RATE = 16_000
        const val FRAME_SAMPLES = 400
        const val FRAME_SHIFT = 160
        const val FIRST_FRAME_START = (FRAME_SHIFT - FRAME_SAMPLES) / 2
        const val FFT_SIZE = 512
        const val MEL_BINS = 80
        const val WINDOW_FRAMES = 61
        const val WINDOW_SHIFT_FRAMES = 48
        const val DECODER_TAIL_SAMPLES = 10_560
        const val PREEMPHASIS = 0.97f
        const val FLOAT_EPSILON = 1.1920929e-7f

        val POVEY_WINDOW = FloatArray(FRAME_SAMPLES) { index ->
            (0.5 - 0.5 * cos(2.0 * PI * index / (FRAME_SAMPLES - 1))).pow(0.85).toFloat()
        }
        val FFT_REVERSED = IntArray(FFT_SIZE) { Integer.reverse(it) ushr Integer.numberOfLeadingZeros(FFT_SIZE - 1) }
        val FFT_COS = FloatArray(FFT_SIZE / 2) { cos(-2.0 * PI * it / FFT_SIZE).toFloat() }
        val FFT_SIN = FloatArray(FFT_SIZE / 2) { sin(-2.0 * PI * it / FFT_SIZE).toFloat() }
        val MEL_FILTERS = buildMelFilters()

        private fun buildMelFilters(): Array<MelFilter> {
            val lowMel = mel(20f)
            val highMel = mel(SAMPLE_RATE / 2f - 400f)
            val delta = (highMel - lowMel) / (MEL_BINS + 1)
            val frequencies = FloatArray(FFT_SIZE / 2) { mel(it * (SAMPLE_RATE.toFloat() / FFT_SIZE)) }
            return Array(MEL_BINS) { index ->
                val left = lowMel + index * delta
                val center = lowMel + (index + 1) * delta
                val right = lowMel + (index + 2) * delta
                val firstBin = frequencies.indexOfFirst { it > left }
                val endBin = frequencies.indexOfFirst { it >= right }
                val weights = FloatArray(endBin - firstBin) { bin ->
                    val frequency = frequencies[firstBin + bin]
                    if (frequency <= center) {
                        (frequency - left) / (center - left)
                    } else {
                        (right - frequency) / (right - center)
                    }
                }
                MelFilter(firstBin, weights)
            }
        }

        private fun mel(frequency: Float): Float = 1127f * ln(1f + frequency / 700f)
    }
}
