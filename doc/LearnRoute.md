# 嵌入式 Linux / 内核 / MCU / AI 方向高价值开源项目清单

结合嵌入式 Linux 开发、内核与驱动、C/C++、MCU/MPU 以及未来 AI 技术需求整理。

---

## **特别推荐（前 5 个）——必须深入研究**

### **1. Linux Kernel**

- **类型**：操作系统内核  
- **价值**：
  - 内核模块、驱动开发、系统调用、调度机制  
  - 深入掌握内核调试（ftrace, perf, kgdb）  
  - 提升复杂嵌入式系统开发能力  
- **技术亮点**：
  - Device Driver（字符设备、I2C/SPI/PCI/USB）  
  - 内核子系统（net, block, usb, power management）  
  - eBPF 与异步 IO  
- **项目地址**：
  - [Linux Kernel Git](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git)
  - [Linux Kernel github](https://github.com/torvalds/linux)

---

### **2. Zephyr Project**

- **类型**：轻量级 RTOS  
- **价值**：
  - MCU/MPU 实时任务管理、硬件抽象、低功耗  
  - 可与 Linux 协同，实现完整嵌入式系统能力  
- **技术亮点**：
  - Device Tree 配置  
  - Sensor/Peripheral 驱动开发  
  - 异步事件与多核处理  
- **项目地址**：[Zephyr GitHub](https://github.com/zephyrproject-rtos/zephyr)  

---

### **3. OpenAMP / RPMsg**

- **类型**：异构多核通信框架  
- **价值**：
  - Linux ↔ MCU 通信，适用于 SoC 或异构芯片  
  - 掌握共享内存、VirtIO 驱动接口  
- **技术亮点**：
  - RPMsg 驱动开发  
  - 跨核任务和 DMA 优化  
  - 对接边缘 AI 加速芯片（NPU/TPU）  
- **项目地址**：[OpenAMP GitHub](https://github.com/OpenAMP/open-amp)  

---

### **4. QEMU / Renode**

- **类型**：嵌入式硬件仿真  
- **价值**：
  - 无需真实硬件即可开发和验证 Linux 驱动  
  - 支持跨 MCU/MPU 平台测试和集成  
- **技术亮点**：
  - QEMU Device Model 开发  
  - Renode 多 MCU 系统仿真  
- **项目地址**：
  - [QEMU 官网](https://www.qemu.org)  
  - [Renode GitHub](https://github.com/renode/renode)  

---

### **5. OpenCV / OpenVINO / TensorFlow Lite Micro**

- **类型**：嵌入式 AI 推理与视觉  
- **价值**：
  - 边缘 AI / 智能硬件应用  
  - 图像处理、传感器数据分析、模型量化优化  
- **技术亮点**：
  - OpenCV: 图像/视频处理，C++ 移植  
  - OpenVINO: Intel NPU/CPU 推理优化  
  - TFLite-Micro: MCU 上 AI 模型部署  
- **项目地址**：
  - [OpenCV GitHub](https://github.com/opencv/opencv)  
  - [OpenVINO GitHub](https://github.com/openvinotoolkit/openvino)  
  - [TFLite-Micro GitHub](https://github.com/tensorflow/tflite-micro)  

---

## **长期跟进（后 5 个）——战略性价值**

### **6. U-Boot**

- **类型**：Bootloader  
- **价值**：
  - 掌握嵌入式启动流程、引导 Linux  
  - 熟悉板级初始化、外设驱动加载  
- **项目地址**：[U-Boot GitHub](https://github.com/u-boot/u-boot)  

---

### **7. FreeRTOS**

- **类型**：轻量 RTOS  
- **价值**：
  - 与 Zephyr 互补，广泛应用于工业 MCU  
  - 掌握任务调度、消息队列、同步机制  
- **项目地址**：[FreeRTOS GitHub](https://github.com/FreeRTOS/FreeRTOS-Kernel)  

---

### **8. LVGL（Light and Versatile Graphics Library）**

- **类型**：嵌入式 GUI 库  
- **价值**：
  - 边缘设备 UI 开发  
  - 与 Linux/RTOS 结合可实现智能交互  
- **项目地址**：[LVGL GitHub](https://github.com/lvgl/lvgl)  

---

### **9. PlatformIO / Zephyr SDK**

- **类型**：嵌入式开发工具链  
- **价值**：
  - 跨平台构建与调试嵌入式项目  
  - 提高开发效率，支持多种 MCU/SoC  
- **项目地址**：[PlatformIO GitHub](https://github.com/platformio/platformio-core)  

---

### **10. Yocto Project**

- **类型**：嵌入式 Linux 构建系统  
- **价值**：
  - 定制 Linux 镜像  
  - 学习 Buildroot / Linux 镜像优化  
- **项目地址**：
  - [Yocto 官网](https://www.yoctoproject.org/)
  - [Yocto source repo](https://git.yoctoproject.org/)

---

## **学习与实践建议**

1. **深研前 5 个项目**：Linux Kernel、Zephyr、OpenAMP、QEMU/仿真、边缘 AI  
   - 目标：打牢底层能力、跨核通信能力、边缘 AI 技术  
   - 对应岗位：高级嵌入式开发、AI 边缘工程师、驱动工程师  
2. **长期跟进后 5 个项目**：U-Boot、FreeRTOS、LVGL、PlatformIO、Yocto  
   - 形成完整嵌入式开发链：启动 → 内核 → 驱动 → AI → 应用 → 构建工具  
3. **学习顺序建议**：
   - 基础驱动与内核 → RTOS 与多核通信 → 仿真与验证 → 边缘 AI → 镜像与工具链优化  
