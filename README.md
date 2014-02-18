KinectFrameTranslator
=====================

An AIR app for translating kinect footage from RGBDToolkit into a time-normalized monochromatic image sequence.
- time-normalized: captured frames aren't necessarily 30fps. RGBDToolkit names frames by the millisecond it was captured. This tool turns the millisecond-timed sequence into a normal sequence by duplicating and dropping frames where needed.
- monochromatic: captured frames interlace their depth data in the red and green channel. This tool uses a pixelbender kernel to turn the 4096 resolution depth into a more friendly 256 resolution monochromatic depth image.
