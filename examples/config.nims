switch("path", "$projectDir/../src")
switch("path", getCurrentDir() & "/src")

# switch("os", "freertos")
# switch("define", "freertosKernelHeap:FreeRTOS-Kernel-Heap3")

include "../template/src/config.nims"

switch("d", "cmakeBinaryDir:" & getCurrentDir() & "/build/examples")
switch("d", "piconimCsourceDir:" & getCurrentDir() & "/template/csource")
switch("d", "futharkgen")

switch("d", "debugSocket")
switch("d", "debugDns")
switch("d", "debugMqtt")

when fileExists("secret.nims"):
  import "../secret.nims"
  when declared(WIFI_SSID):
    switch("d", "WIFI_SSID:" & WIFI_SSID)
  when declared(WIFI_PASSWORD):
    switch("d", "WIFI_PASSWORD:" & WIFI_PASSWORD)
  when declared(MQTT_USER):
    switch("d", "MQTT_USER:" & MQTT_USER)
  when declared(MQTT_PASS):
    switch("d", "MQTT_PASS:" & MQTT_PASS)

