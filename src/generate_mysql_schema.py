#!/usr/bin/env python

import sys
import csv
import argparse
import gzip
csv.field_size_limit(sys.maxsize)


def main(args):
    table_name = args.input if args.table is None else args.table

    info = dict()
    my_open = gzip.open if args.input.endswith('.gz') else open
    delim = ',' if args.input.rstrip('.gz').endswith('.csv') else '\t'

    reader = csv.reader(my_open(args.input), delimiter=delim)
    header = reader.next()

    for column in header:
        info[column] = {
            "type": 'INT',
            "maxlength": 0,
            "values": set()
        }

    if args.n == 'all':
        n = float('inf')
    else:
        n = int(args.n)

    i = 1
    for row in reader:
        for i, value in enumerate(row):
            # Check if field is larger than max length
            if len(value) > info[header[i]]['maxlength']:
                info[header[i]]['maxlength'] = len(value)

            # If only a few values, consider an enum
            if 'values' in info[header[i]]:
                info[header[i]]['values'].add(value)
                if len(info[header[i]]['values']) > 4:
                    del info[header[i]]['values']

            if info[header[i]]['type'] == 'VARCHAR':
                if len(value) > 255:
                    info[header[i]]['type'] = 'TEXT'
            elif info[header[i]]['type'] != 'TEXT':
                try:
                    # Default is integer
                    floaty = float(value)
                    inty = int(floaty)
                    # Make sure it's not a float
                    if floaty != inty:
                        info[header[i]]['type'] = 'FLOAT'
                except (ValueError, OverflowError):
                    # If too long, make text
                    if len(value) > 255:
                        info[header[i]]['type'] = 'TEXT'
                    # Otherwise, a varchar
                    else:
                        info[header[i]]['type'] = 'VARCHAR'
        if i == n: break
        i += 1 


    field_names = []
    colnames = []
    for i, column in enumerate(header):
        col_type = info[column]['type']
        col_meta = '(%s)' % info[column]['maxlength'] if col_type != 'FLOAT' else ''
        if args.enum and 'values' in info[header[i]]:
            col_type = 'ENUM'
            col_meta = "('%s')" % "', '".join(info[header[i]]['values'])
            if not info[header[i]]['values'] - set(['TRUE', 'FALSE']):
                col_type = 'BOOLEAN'
                col_meta = ''

        colname = column[:64].lower().replace(' ', '_').replace('(', '').replace(')', '').replace('/', '_').replace('-', '_').replace('>', 'gt').replace('<', 'lt').replace('#', 'no').replace('%', 'perc')
        if colname == '':
            colname = 'none'
        if colname in colnames:
            # If column already exists, need new one
            version = 1
            while '%s_%s' % (colname, version) not in colnames:
                version += 1
            colname = '%s_%s' % (colname, version)
        colnames.append(colname)
        field_names.append("`%s` %s%s DEFAULT NULL" % (colname, col_type, col_meta))

    epilog = '' if args.sqlite else "ENGINE=MyISAM DEFAULT CHARSET=latin1"
    print "CREATE TABLE `%s` (\n %s\n) %s;" % (table_name, ",\n ".join(field_names), epilog)

if __name__ == '__main__':
    INFO = """Generates MySQL create statement from file (tsv or csv) using header as column names. Inspired by Nick Tatonetti's tableize"""
    parser = argparse.ArgumentParser(description=INFO)

    parser.add_argument('input', help='Input file; may be gzipped')
    parser.add_argument('--table', '-t', help='Table name (default: <input>)')
    parser.add_argument('--enum', help='Use enums where possible', action='store_true')
    parser.add_argument('--sqlite', help='Create statement for sqlite instead of MySQL', action='store_true')
    parser.add_argument('-n', help='Stop after n lines', default='all')
    args = parser.parse_args()
    main(args)