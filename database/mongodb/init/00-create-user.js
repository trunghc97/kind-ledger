// Create user for kindledger database
// First create user in admin database
db = db.getSiblingDB('admin');

// Create user in admin database with access to kindledger database
db.createUser({
  user: 'kindledger',
  pwd: 'kindledger123',
  roles: [
    {
      role: 'readWrite',
      db: 'kindledger'
    },
    {
      role: 'dbAdmin',
      db: 'kindledger'
    }
  ]
});

print('User kindledger created successfully in admin database with access to kindledger database');
