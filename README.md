# SAC_robotic_arm
This repository documents and extends the MATLAB tutorial “Train SAC Agent for Ball Balance Control” and adds extra visualization utilities for analysis during/after training. All core content, models, and the SAC training workflow are created and owned by MathWorks (MATLAB). This repo contributes small parameter tweaks and additional plotting code focused on agent behaviour and episode analytics.

Tutorial reference: https://uk.mathworks.com/help/reinforcement-learning/ug/train-sac-agent-for-ball-balance-control.html

# What’s in this repo
Edited visualisation function: animatedPath.m
Adds two analyses after the default animation:
Distance-to-target vs time plot with a tolerance band.
Ball position density heatmap (2‑D occupancy/dwell-time map).
Notes and instructions to integrate these visuals with the MATLAB tutorial project.
Optional helper snippets for computing KPIs such as RMSE and settling time.

This repo does not redistribute the MathWorks example models or agent files. Please obtain the example directly from MathWorks via the tutorial link above.


![0_gjbW2m2KHh9gyQlP](https://github.com/user-attachments/assets/53990f2b-4289-42bf-945d-bf43b70d7772)
