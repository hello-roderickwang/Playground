import sys

print('Start Printing:')

print('type of sys.argv[0]:', type(sys.argv[0]))
print('type of '':', type(''))

if sys.argv[0] == '':
	print('sys.argv[0] is Empty')
else:
	print(sys.argv[0])
	print('Other')