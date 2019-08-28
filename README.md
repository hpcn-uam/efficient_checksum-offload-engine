# Efficient_checksum-offload-engine

In this repository you can find different implementations to tackle efficient checksum computation in just 3.1 ns.

Most of them does not meet timing, but cksum_vhdl_big_red3, checksumRed34to2.v and checksumRed35to3 do.

## Citation

The code in this repository is part of the work presented in the paper "FPGA-based TCP/IP Checksum Offloading Engine for 100 Gbps Networks"

If you find this code interesting, you can cite our work:

```
@inproceedings{sutter2018fpga,
  title={{FPGA-based TCP/IP Checksum Offloading Engine for 100 Gbps Networks}},
  author={Sutter, Gustavo and Ruiz, Mario and Lopez-Buedo, Sergio and Alonso, Gustavo},
  booktitle={2018 International Conference on ReConFigurable Computing and FPGAs (ReConFig)},
  pages={1--6},
  year={2018},
  organization={IEEE},
  doi={10.1109/RECONFIG.2018.8641729}, 
  ISSN={2640-0472}, 
}
```