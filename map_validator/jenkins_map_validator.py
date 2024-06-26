import os
import sys
import argparse
import map_validator as map_validator

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

def main(args):

    missing_fields = map_validator.validate_required_fields(args.map, args.verbose)
    failed_perts = map_validator.validate_pert_ids(args.map, args.verbose)

    if (len(missing_fields) > 0):
        errorMessage = args.map + ' missing following required fields: {}'.format(', '.join(missing_fields))
        print(errorMessage)
        sys.exit(-1)
    if (len(failed_perts) > 0):
        for errorMessage in failed_perts:
            print("i: {i}, pert_id: {pert_id}, reason: {reason}".format(
                errorMessage.i,
                errorMessage.pert_id,
                errorMessage.reason
            ))
        sys.exit(-1)
    print('map validated successfully')
    sys.exit(0)




if __name__ == "__main__":
    args = build_parser().parse_args(sys.argv[1:])
    main(args)
