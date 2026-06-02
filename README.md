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
```
matlab-lens-simulator/
├── LensSimulatorApp.mlapp   % Main GUI (MATLAB App Designer)
├── lensCalcSafe.m           % Core computation engine
├── drawRayDiagram.m         % Principal ray diagram renderer
├── drawSetupOnly.m          % Degenerate-case diagram handler
├── drawArrow.m              % Scaled arrow drawing utility
├── plotPerformance.m        % Magnification vs. object distance plot
├── tern.m                   % Ternary conditional utility
└── README.md
```

## How It Works

The simulator is grounded in the **thin lens equation**:
1/f = 1/v + 1/u

For two-lens systems, the image from Lens 1 becomes the object for Lens 2:
u₂ = d - v₁
m_total = m₁ × m₂

When lenses are in contact (d = 0), an effective focal length is applied:
1/f_eff = 1/f₁ + 1/f₂

---

## Test Cases

The simulator was validated against 13 optical configurations:

| # | Mode | u | f₁ | f₂ | d | Nature | Orientation |
|---|------|---|----|----|---|--------|-------------|
| 1 | Single | 30 | 10 | — | — | Real | Inverted |
| 2 | Single | 20 | 10 | — | — | Real | Inverted |
| 3 | Single | 15 | 10 | — | — | Real | Inverted |
| 4 | Single | 10 | 10 | — | — | At ∞ | — |
| 5 | Single | 5 | 10 | — | — | Virtual | Upright |
| 6 | Single | 20 | −10 | — | — | Virtual | Upright |
| 7 | Two | 20 | 10 | 10 | 30 | At ∞ | — |
| 8 | Two | 20 | 10 | 12 | 25 | Virtual | Inverted |
| 9 | Two | 20 | 10 | −8 | 30 | Virtual | Inverted |
| 10 | Two | 15 | 10 | 10 | 8 | Real | Inverted |
| 11 | Two | 20 | 10 | 5 | 25 | At ∞ | — |
| 12 | Two | 20 | 10 | 8 | 20 | Undefined | — |
| 13 | Two | 20 | 10 | 15 | 0 | Real | Inverted |

All distances in metres.

---

## Authors

- **Saleh Ahmed** (2306021)
- **Shahrim Al Farabi** (2306022)

Department of EEE, BUET — Level 2, Term 1  
Submitted to: Dr. Hafiz Imtiaz, Professor, Dept. of EEE

---

## License

This project is released under the [MIT License](LICENSE).
