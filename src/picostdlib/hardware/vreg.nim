import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_vreg/include".}
{.push header: "hardware/vreg.h".}

type
  VregVoltage* {.pure, importc: "enum vreg_voltage".} = enum
    V0_85 = 0b0110 # 0.85v
    V0_90 = 0b0111 # 0.90v
    V0_95 = 0b1000 # 0.95v
    V1_00 = 0b1001 # 1.00v
    V1_05 = 0b1010 # 1.05v
    V1_10 = 0b1011 # 1.10v
    V1_15 = 0b1100 # 1.15v
    V1_20 = 0b1101 # 1.20v
    V1_25 = 0b1110 # 1.25v
    V1_30 = 0b1111 # 1.30v

const
  VregVoltageMin* = VregVoltage.V0_85     # Always the minimum possible voltage
  VregVoltageDefault* = VregVoltage.V1_10 # Default voltage on power up.
  VregVoltageMax* = VregVoltage.V1_30     # Always the maximum possible voltage

proc vregSetVoltage*(voltage: VregVoltage) {.importc: "vreg_set_voltage".}
  ## Set voltage
  ##
  ## \param voltage  The voltage (from enumeration \ref vreg_voltage) to apply to the voltage regulator

{.pop.}
