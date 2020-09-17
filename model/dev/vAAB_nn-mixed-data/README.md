# Updated model for v1 to send

Contains a signal chain complete signal chain that generates a bundled windows rampsim binary. See compileIn.h for 
the sim netlist.

Changes were made in Drobox to make this work
- changes in `RAMP_OPERATOR` to remove duplicate lines from netlists
- created `ramp.learn.ideal` (it's in the `nn_ideal directory`, need to fix how that parses so that it doesn't drop the `nn_`).
  This replaces the normal neural net and doesn't try to do any hardware specific scaling. This is temporary and needs
  a finetooth review.
- added a LPF to the sim netlist of `ramp.ops.zcr` in order to match the matlab better. This is a temp fix.

## Files

- **gb_test.m** - Run test
- **gb_train.m** - 
- **gb_model_2020_09_09.m** - Defines the model
- [**Preparation notes**](gb_characterization_pre_send.ipynb)
