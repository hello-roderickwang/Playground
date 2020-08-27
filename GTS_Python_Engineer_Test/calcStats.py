import csv
import argparse
import statistics

parser = argparse.ArgumentParser()
parser.add_argument('--inputFile', dest='infile', help='input file', metavar='INPUT_FILE')
parser.add_argument('--outputFile', dest='outfile', help='output file', metavar='OUTPUT_FILE')
args = parser.parse_args()

dict_symbol = {}
dict_exchange = {}
total_bought = 0
total_sold = 0
total_bought_notional = 0
total_sold_notional = 0
trade = []

with open(args.infile, 'r') as input_file:
    csv_reader = csv.reader(input_file, delimiter=',')
    line_counter = 0
    with open(args.outfile, 'w') as output_file:
        csv_writer = csv.writer(output_file)
        for row in csv_reader:
            if line_counter == 0:
                write_line = row
                write_line.extend(['SymbolBought', 'SymbolSold', 'SymbolPosition', 'SymbolNotional', \
                                   'ExchangeBought', 'ExchangeSold', 'TotalBought', 'TotalSold',\
                                   'TotalBoughtNotional', 'TotalSoldNotional'])
                csv_writer.writerow(write_line)
                line_counter += 1
                continue
            if row[1] == 'LNCH':
                continue
            notional = float(row[4]) * float(row[5])
            trade.append(int(row[4]))
            if row[1] not in dict_symbol:
                dict_symbol[row[1]] = [0, 0]
            if row[6] not in dict_exchange:
                dict_exchange[row[6]] = [0, 0]
            if row[3] in {'t', 's'}:
                dict_symbol[row[1]][1] += int(row[4])
                dict_exchange[row[6]][1] += int(row[4])
                total_sold += int(row[4])
                total_sold_notional += notional
            else:
                dict_symbol[row[1]][0] += int(row[4])
                dict_exchange[row[6]][0] += int(row[4])
                total_bought += int(row[4])
                total_bought_notional += notional
            write_line = row
            write_line.append(dict_symbol[row[1]][0])
            write_line.append(dict_symbol[row[1]][1])
            write_line.append(dict_symbol[row[1]][0] - dict_symbol[row[1]][1])
            write_line.append(round(notional, 2))
            write_line.append(dict_exchange[row[6]][0])
            write_line.append(dict_exchange[row[6]][1])
            write_line.append(total_bought)
            write_line.append(total_sold)
            write_line.append(round(total_bought_notional, 2))
            write_line.append(round(total_sold_notional, 2))
            csv_writer.writerow(write_line)
            line_counter += 1

print('Processed Trades: ', line_counter - 1)

print('Share Bought: ', total_bought)
print('Share Sold: ', total_sold)
print('Total Volume: ', total_bought + total_sold)
print('Notional Bought: $', round(total_bought_notional, 2))
print('Notional Sold: $', round(total_sold_notional, 2))

for exchange in dict_exchange.keys():
    print(exchange, ' Bought: ', dict_exchange[exchange][0])
    print(exchange, ' Sold: ', dict_exchange[exchange][1])

print('Average Trade Size: ', round(statistics.mean(trade), 2))
print('Median Trade Size: ', statistics.median(trade))

symbols = []
for symbol in dict_symbol.keys():
    symbols.append([sum(dict_symbol[symbol]), symbol])
symbols.sort(reverse=True)
num_active = min(10, len(symbols))
print(num_active, 'Most Active Symbols:')
for i in range(num_active):
    print(str(symbols[i][1]) + '(' + str(symbols[i][0]) + ')')