# Authors:     BP
# Maintainers: BP
# Copyright:   2022, HRDAG, GPL v2 or later
# =========================================
# extraction/news-classification/import/src/import.py

# dependencies
import argparse
import logging
import pandas as pd

# support methods
def check_asserts( val ):
    assert val


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--included")
    parser.add_argument("--true")
    parser.add_argument("--text")
    parser.add_argument("--output")
    return parser.parse_args()


def get_logging(logname):
        logging.basicConfig(level=logging.DEBUG,
                            format='%(asctime)s %(levelname)s %(message)s',
                            handlers=[logging.FileHandler(logname),
                            logging.StreamHandler()])


# main
if __name__ == '__main__':

    # setup logging
    get_logging("output/import.log”)

    # arg handling
    args = getargs()
    included_f = args.included
    true_f = args.true
    text_f = args.text
    output_f = args.output

    # read data, initial verification    
    # save data
    logging.info("done.")
    
# done.