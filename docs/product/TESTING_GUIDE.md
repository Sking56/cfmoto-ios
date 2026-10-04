# Testing guide

Current portable checks: python Tools/verify_repository.py and python -m unittest discover -s Tests -p 'test_*.py' -v. Native check: python Tools/verify_xcode.py on a suitable Mac. Record the exact commit and real results.

Future hardware tests, not currently executable: TEST-PROJ-001 establishes pairing, explicitly grants capture, switches to Waze and observes the TFT for >=30 minutes. TEST-PROJ-002 repeats with Apple Maps. TEST-REC-001 interrupts Wi-Fi and checks bounded recovery/no crash. TEST-STOP-001 stops capture and confirms normal TFT restoration. TEST-LOG-001 exports diagnostics and checks for private content. Run while stationary. Record bike firmware, phone/iOS, app SHA, duration, errors and actual outcomes in engineering/HARDWARE_INTEGRATION.md; do not mark these passed before implemented.
