# MIPI CSI 2 Receiver

[![Build Status](https://travis-ci.com/hdl-util/mipi-csi-2.svg?branch=master)](https://travis-ci.com/hdl-util/mipi-csi-2)

## To-do List
* Primary format decoding
    * [x] RGB888
    * [x] RGB565
    * [x] YUV422 8-bit
    * [x] RAW8
    * [ ] RAW10
* Tests
    * [x] D-PHY
    * [x] CSI-2
    * [ ] Decoding
* Error-checking and correction
    * [ ] Header ECC
    * [ ] Footer Checksum
* N-lane
    * [x] 1 lane
    * [x] 2 lane
    * [ ] 3 lane
        * Roadblock: will receive more bytes than the 32-bit buffer
            * Consider long packet with 8 bytes
            * First 3 from header go from corresponding lanes
            * Header byte 4 comes from lane 1, Data byte 1, 2 come from lanes 2 & 3
            * Data byte 3, 4, 5 (!) come from lanes 1, 2, & 3
            * Thus, you are stuck with extra, on the same clock the user gets the buffer
    * [x] 4 lane

## Reference Documents

These documents are not hosted here! They are available on Library Genesis and at other locations.

* [MIPI CSI-2 Specification](https://b-ok.cc/book/5370801/fbaeb9)
* [MIPI D-PHY Specification](https://b-ok.cc/book/5370804/7f174a)

## Special Thanks

* [Gaurav Singh's posts on his IMX219 CSI-2 RX implementation](https://www.circuitvalley.com/2020/02/imx219-camera-mipi-csi-receiver-fpga-lattice-raspberry-pi-camera.html)
