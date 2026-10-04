# Video

Gate 2 synthetic implementation: owned BGRA pixel buffers, synchronous single-frame VideoToolbox H.264 encoding, bounded Annex-B conversion and a generation-scoped predictive-chain queue. The host probe pulls twelve frames; the independent receiver decodes and checks them. The app compiles these sources but does not run the encoder or capture a screen yet.

See [pipeline and limits](../../docs/engineering/VIDEO_PIPELINE.md) and run `python Tools/verify_gate2.py` on macOS. No third-party runtime dependency, saved screen content or hardware compatibility claim is introduced.
