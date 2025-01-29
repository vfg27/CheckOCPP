# CheckOCPP

CheckOCPP is a Wireshark dissector for the Open Charge Point Protocol (OCPP). It provides an efficient and scalable solution for passive compliance audits by automatically detecting OCPP versions, validating message structures, and flagging non-compliant packets.

## Features
- **Automatic OCPP version detection**: Identifies whether captured traffic corresponds to OCPP 1.6, 2.0, or 2.0.1.
- **Protocol compliance validation**: Checks message structure and schema conformity.
- **Non-compliant packet highlighting**: Flags invalid packets to aid debugging and compliance verification.
- **IPv4/IPv6 traffic distinction**: Provides a visual indicator for OCPP packets transmitted over IPv4.
- **Two dissector implementations**:
  - **Single dissector**: Processes OCPP packets without distinguishing between versions.
  - **Separate dissectors**: Assigns a distinct dissector to each OCPP version for more precise analysis.

## Installation

1. Ensure you have Wireshark installed on your system.
2. Modify the path to the schemas in the `.lua` files.
3. Use 'make install-single' or 'make install-multiple' to install the dissector.
4. Restart Wireshark to load the dissector.

## Usage

1. Open Wireshark and start capturing network traffic.
2. Apply the filter `ocpp` to isolate OCPP traffic if single dissector is installed. If not, search by `ocpp1.6`, `ocpp2.0`, or `ocpp2.0.1`.
3. Add the coloring rules.
4. Expand the OCPP protocol details to inspect message type, message ID, and payload validation results.
5. Look for highlighted packets to identify non-compliant or misconfigured OCPP messages.

## Limitations
- CheckOCPP only works with unencrypted traffic. If TLS is enabled, decryption keys are required.
- It only validates OCPP JSON version, not SOAP version.



