# MIPI CSI 2 Receiver

[![Build Status](https://travis-ci.com/hdl-util/mipi-csi-2.svg?branch=master)](https://travis-ci.com/hdl-util/mipi-csi-2)

## To-do List
* Image format decoding
    * [ ] RGB
    * [ ] YUV
    * [ ] RAW
* Tests
    * [x] D-PHY
    * [ ] CSI-2
    * [ ] Bayer (?)
* Errors
    * [ ] Header ECC
    * [ ] Footer Checksum
* N-lane
    * [x] 1 lane
    * [x] 2 lane
    * [ ] 3 lane
        * Roadblock: will receive more bytes than the 32-bit buffer
    * [x] 4 lane

## Reference Documents

These documents are not hosted here! They are available on Library Genesis and at other locations.

* [MIPI CSI-2 Specification](https://b-ok.cc/book/5370801/fbaeb9)
* [MIPI D-PHY Specification](https://b-ok.cc/book/5370804/7f174a)

## Special Thanks

* [Gaurav Singh's posts on his CSI-2 RX implementation](https://www.circuitvalley.com/2020/02/imx219-camera-mipi-csi-receiver-fpga-lattice-raspberry-pi-camera.html)

