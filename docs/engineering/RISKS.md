# Risk register

| Risk | Status | Required evidence / mitigation |
|---|---|---|
| iOS 27 capture/background API assumptions | Research pending | Primary Apple docs plus signed-device probe |
| Bike protocol differs by firmware | Open | Pin Android source and capture sanitized 450NK negotiation |
| Wi-Fi and cellular routing conflict | Open | Test real routes while Maps/Waze foreground |
| Copyleft / attribution obligations | Open | License audit before code reuse |
| No local Xcode / iPhone / motorcycle | Confirmed | Mac build and hardware verification remain pending |
| Encoder, thermal, buffering constraints | Open | Bounded design and >=30 minute device test |
