# Optical Lens System Simulator (MATLAB GUI)

An interactive MATLAB GUI for simulating and analyzing single-lens and two-lens optical systems. Developed as a course project for EEE 212 — Numerical Technique Laboratory at Bangladesh University of Engineering & Technology (BUET).

---

## Overview

This simulator computes image distances, magnifications, image nature (real/virtual), and orientation (erect/inverted) for user-defined lens parameters. It generates accurate ray diagrams and performance plots showing how magnification varies with object distance — covering all standard and edge-case optical configurations.

---

## Features

- Single-lens and two-lens simulation modes
- Interactive ray diagram with three principal rays (parallel, central, focal)
- Magnification vs. object distance performance plot
- Handles edge cases: object at focal point, virtual objects (u₂ < 0), lenses in contact (d = 0), degenerate case (u₂ = 0)
- Paraxial approximation warnings for large ray angles (> 30°)
- Copy Output button for quick report export

---

## Requirements

- MATLAB R2019b or later (App Designer support required)
- No additional toolboxes required

---

## Getting Started

```matlab
% Clone the repository
git clone https://github.com/YOUR_USERNAME/matlab-lens-simulator

% Open MATLAB, navigate to the project folder, then run:
open('LensSimulatorApp.mlapp')
```

Press **RUN** inside the app after setting your parameters.

---

## Project Structure
