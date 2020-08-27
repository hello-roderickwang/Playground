# import sys

# print('Start Printing:')
# print('type of sys.argv[0]:', type(sys.argv[0]))
# print('type of '':', type(''))

# if sys.argv[0] == '':
# 	print('sys.argv[0] is Empty')
# else:
# 	print(sys.argv[0])
# 	print('Other')


# # assert statement
# def apply_discount(product, discount):
# 	price = int(product['price'] * (1.0 - discount))
# 	assert 0 <= price <= product['price'], 'This is assert exception'
# 	return price

# shoes = {'name': 'Fancy Shoes', 'price':14900}

# # legal
# print(apply_discount(shoes, 0.25))
# # illegal
# apply_discount(shoes, 2)

# # in python, tuple always true
# if (False,False):
# 	print('tuple always true')
# else:
# 	print('false')

# summary
# 1. Python's assert statement is a debugging aid that tests a condition as an internal self-check in your program.
# 2. Assert should only be used to help developers identify bugs. They're not a mechanism for handling run-time errors.
# 3. Assert can be globally disabled with an interpreter setting.



