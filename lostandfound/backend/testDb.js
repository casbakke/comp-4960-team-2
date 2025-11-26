const {
  createItem,
  getItems
} = require('./itemRepository');

async function run() {
  console.log('Creating sample item...');

  const newItem = await createItem({
    type: 'lost',
    title: 'Black Backpack',
    category: 'backpack',
    description: 'Has a silver MacBook inside.',
    building: 'Dobbs Hall',
    locationDetails: '3rd floor hallway',
    ownerName: 'Aliyan Hidayatallah',
    ownerPhone: '555-555-5555',
    ownerEmail: 'hidayatallaha@wit.edu'
  });

  console.log('Created item:', newItem);

  console.log('\nFetching all lost items:');
  const items = await getItems({ type: 'lost' });
  console.log(items);
}

run().then(() => {
  console.log('\nDone.');
  process.exit(0);
}).catch(err => {
  console.error('Error:', err);
  process.exit(1);
});