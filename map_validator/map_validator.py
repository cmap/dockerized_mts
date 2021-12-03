import os
import sys
import argparse
import pandas as pd

def build_parser():
    parser = argparse.ArgumentParser(description=__doc__,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument("--map", "-f",
        help="Required: Map file",
        type=str, required=True)

    parser.add_argument("--verbose", '-v',
        help="Print extra information",
        action="store_true", default=False)

    return parser



REQUIRED_FIELDS = {
  'pert_dose',
  'pert_id',
  'pert_plate',
  'pert_iname',
  'pert_type',
  'x_project_id',
  'pert_vehicle',
  'pert_well'
}


def main(args):
    mapfile = pd.read_csv(args.map, sep='\t')

    map_hds = set(mapfile.columns)

    if args.verbose:
        print(REQUIRED_FIELDS)
        print(map_hds)

    missing_fields = REQUIRED_FIELDS.difference(map_hds)

    if (len(missing_fields) > 0):
        print('missing following required fields: {}'.format(', '.join(missing_fields)))
        sys.exit(-1)
    else:
        print('map validated successfully')
        sys.exit(0)



if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])
    main(args)
