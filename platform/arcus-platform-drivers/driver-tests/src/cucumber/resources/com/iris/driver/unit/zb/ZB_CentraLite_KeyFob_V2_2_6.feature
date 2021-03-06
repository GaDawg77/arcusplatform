@Zigbee @CentraLite @KeyFob @V2
Feature: Test of the CentraLite KeyFob ZigBee driver
    
    These scenarios test the functionality of the CentraLite KeyFob ZigBee driver.

    Background:
        Given the ZB_CentraLite_KeyFob_V2_2_6.driver has been initialized
            And the device has endpoint 1

    @basic
    Scenario: Driver reports capabilities to platform.
        When a base:GetAttributes command is placed on the platform bus
        Then the driver should place a base:GetAttributesResponse message on the platform bus
            And the message's base:caps attribute list should be ['base', 'dev', 'devadv', 'devconn', 'devpow', 'pres', 'devota', 'ident']
            And the message's dev:devtypehint attribute should be Keyfob
            And the message's devadv:drivername attribute should be ZBCentraLiteKeyFobV2 
            And the message's devadv:driverversion attribute should be 2.6
            And the message's devpow:source attribute should be BATTERY
            And the message's devpow:linecapable attribute should be false
            And the message's devpow:backupbatterycapable attribute should be false
        Then both busses should be empty


############################################################
# General Driver Tests
############################################################

    @basic @name
    Scenario Outline: Make sure driver allows device name to be set 
        When a base:SetAttributes command with the value of dev:name <value> is placed on the platform bus
        Then the platform attribute dev:name should change to <value>

        Examples:
          | value                    |
          | Fob                      |
          | "Key Fob"                |
          | "Mom's Keys"             |
          | "Mom & Dad's Keys"       |


############################################################
# Driver Lifecycle Tests
############################################################

    @basic @added
    Scenario: Device added
        When the device is added
        Then the capability devpow:sourcechanged should be recent
            And the capability but:statechanged.a should be recent
            And the capability but:statechanged.b should be recent
            And the capability but:statechanged.home should be recent
            And the capability but:statechanged.away should be recent
            And the capability pres:presencechanged should be recent
            And the capability pres:presence should be PRESENT
            And the capability pres:usehint should be UNKNOWN
            And the capability pres:person should be UNSET
        Then the driver should send bindAll endpoints

    @timeout
    Scenario: Connect device
        When the device is connected
        Then the driver should place a base:ValueChange message on the platform bus
            And the capability pres:presence should be PRESENT
            And the capability pres:presencechanged should be recent
        Then the driver should send pollcontrol setlongpollinterval
            And with parameter newLongPollInterval 24
        Then the driver should send pollcontrol setShortPollInterval
            And with parameter newShortPollInterval 2
        Then the driver should send power zclReadAttributes
            And with attribute ATTR_BATTERY_VOLTAGE
            And with attribute ATTR_BATTERY_VOLTAGE_MIN_THRESHOLD
        Then the driver should send diagnostics zclReadAttributes
            And with attribute ATTR_LAST_MESSAGE_LQI
            And with attribute ATTR_LAST_MESSAGE_RSSI
        Then the driver should set timeout at 10 minutes
        Then both busses should be empty

    # onDisconnected
    Scenario: Disconnected device
        When the device is disconnected
        Then the capability pres:presence should be ABSENT
            And the capability pres:presencechanged should be recent
    

############################################################
# Power Cluster Tests
############################################################

    @Power
    Scenario Outline: Power Read / Report
        Given the capability devpow:battery is 90
        When the device response with power <messageType> 
            And with parameter ATTR_BATTERY_VOLTAGE <voltage>
            And with parameter ATTR_BATTERY_VOLTAGE_MIN_THRESHOLD 21
            And send to driver
        Then the driver should place a base:ValueChange message on the platform bus
            And the message's devpow:battery attribute numeric value should be within delta 1.1 of <battery>
    
        Examples:
          | messageType               | voltage | battery | remarks                 |
          | zclreadattributesresponse | 0       | 90      | ignore invalid 0 values |
          | zclreadattributesresponse | 20      | 0       | below min should be 0   |
          | zclreadattributesresponse | 21      | 0       |                         |
          | zclreportattributes       | 25      | 44      |                         |
          | zclreportattributes       | 30      | 100     |                         |
          | zclreportattributes       | 31      | 100     | above max should be 100 |

    # event CNFG_PWR_RPT
    Scenario: trigger event CNFG_PWR_RPT
    Given the driver variable CNFG_PWR_RPT is 0
        When event CnfgPwrRpt trigger
        Then the driver should send 0x0001 0x06    
         

############################################################
# Poll Control Cluster Tests
############################################################

    @Poll
    Scenario Outline: poll control read / report
        When the device response with pollcontrol <messageType>
        And with parameter ATTR_CHECKIN_INTERVAL 1
        And with parameter ATTR_LONG_POLL_INTERVAL 1
        And with parameter ATTR_SHORT_POLL_INTERVAL 1
        And send to driver

        Examples:
          | messageType               |
          | zclreadattributesresponse |
          | zclreportattributes       |

    @Poll
    Scenario: poll control check in
        When the device response with pollcontrol checkin
            And send to driver
        Then the driver should send pollcontrol checkinresponse    
    
    # event CNFG_POLL_CTRL
    Scenario: trigger event CNFG_POLL_CTRL
        Given the driver variable CNFG_POLL_CTRL is 0
        When event CnfgPollCrtl trigger
        Then the driver should send 0x0020 0x02
         

############################################################
# Diagnostics Cluster Tests
############################################################

    @Diagnostics
    Scenario Outline: diagnostics read / report response
        When the device response with diagnostics <messageType>
            And with parameter ATTR_LAST_MESSAGE_RSSI <rssi>
            And with parameter ATTR_LAST_MESSAGE_LQI <lqi>
            And send to driver
        Then the capability devconn:signal should be <signal> 
    
        Examples:
          | messageType               | rssi | lqi      | signal |
          | zclreadattributesresponse | 10   | 10       | 4      |
          | zclreportattributes       | 10   | INVALID  | 100    |

    #event CnfgDiagRpt
    Scenario: Event CnfgDiagRpt
        Given the driver variable CNFG_DIAG_RPT is 0
        When event CnfgDiagRpt trigger
        Then the driver should send 0x0B05 0x06


############################################################
# OTA Cluster Tests
############################################################

    # ota.zclreadattributesresponse
    @OTA
    Scenario: OTA read response
        Given the capability devota:targetVersion is 1
        When the device response with ota zclreadattributesresponse
            And with parameter ATTR_CURRENT_FILE_VERSION 1
            And send to driver
        Then the driver should place a base:ValueChange message on the platform bus
            And the capability devota:currentVersion should be 1
            And the capability devota:status should be COMPLETED
    
    # ota.querynextimagerequest
    @OTA
    Scenario: OTA query next image
        Given the capability devota:targetVersion is 1
        When the device response with ota querynextimagerequest
            And with parameter manufacturerCode 1
            And with parameter imageType 1
            And with parameter fileVersion 1
            And with header flags 1
            And send to driver
        Then the driver should place a base:ValueChange message on the platform bus
            And the capability devota:currentVersion should be 1
            And the capability devota:status should be COMPLETED
    
    #ota.imageblockrequest / imagePageRequest
    @OTA
    Scenario Outline: OTA image block / page
        Given the capability devota:status is IDLE
        When the device response with ota <messageType>
            And with parameter fileVersion 1
            And with parameter fileOffset 0
            And with header flags 1
            And send to driver 
        Then the driver should place a base:ValueChange message on the platform bus
            And the capability devota:targetVersion should be 1
            And the capability devota:status should be INPROGRESS
    
        Examples:
          | messageType       |
          | imageblockrequest |
          | imagePageRequest  |
    
    
    # ota.upgradeendrequest
    @OTA
    Scenario Outline: OTA upgrade end request
        When the device response with ota upgradeendrequest
            And with parameter status <status>
            And with parameter manufacturerCode 0
            And with parameter imageType 0
            And with parameter fileVersion 0
            And with header flags 1
            And send to driver 
        Then the driver should place a base:ValueChange message on the platform bus
            And the capability devota:status should be <result>

        Examples:
          | status | result    |
          |    0   | COMPLETED |
          |   -1   | FAILED    |


############################################################
# Misc Tests
############################################################

    #setAttributes pres
    Scenario: Set attribute presence
        When the capability method base:SetAttributes
            And with capability pres:person is Joe Doe
            And with capability pres:usehint is PERSON
            And send to driver
        Then the capability pres:person is Joe Doe
            And the capability pres:usehint is PERSON
    
    #onoffswitch.zclreadattributesresponse
    Scenario: on off switch read response
        When the device response with onoffswitch zclreadattributesresponse
            And with parameter ATTR_SWITCH_TYPE 1
            And with parameter ATTR_SWITCH_ACTIONS 1
            And send to driver
    

############################################################
# Identify Cluster Tests
############################################################

    Scenario: identify
        When the capability method ident:Identify
            And send to driver
        Then the driver should send identify identifyCmd    


############################################################
# ZigBee Ack/Response Message Tests
############################################################

    Scenario Outline: default ZigbeeMessage processing
        When the device response with <cluster> <command>
            And send to driver

        Examples:
          | cluster | command | remarks                                |
          | 0x0001  | 0x07    | CLUSTER_PWR_CNFG,     CMD_CNFG_RPT_RSP |
          | 0x0020  | 0x04    | CLUSTER_POLL_CONTROL, CMD_WRT_ATTR_RSP |
          | 0x0020  | 0x0B    | CLUSTER_POLL_CONTROL, CMD_DFLT_RSP     |
          | 0x0B05  | 0x07    | CLUSTER_DIAGNOSTICS,  CMD_CNFG_RPT_RSP |

