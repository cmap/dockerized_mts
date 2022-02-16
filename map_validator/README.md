# Map Validator Module

##  Map Validator Overview

Validates source map file, which provides metadata for downstream processing. 

## Execution

For more information using python run:

```
$ python jenkins_map_validator.py --help
usage: jenkins_map_validator.py [-h] --map MAP [--verbose]

optional arguments:
  -h, --help         show this help message and exit
  --map MAP, -f MAP  Required: Map file (default: None)
  --verbose, -v      Print extra information (default: False)
```


### Example usage with Python

```
python jenkins_map_validator.py -f PRJ_A001.map
```
