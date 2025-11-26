// This file is the database layer - this will be imported while writing backend

const { db } = require('./firebase');

const itemsCollection = db.collection('items');

async function createItem(data) {
  const now = new Date();

  const newItem = {
    type: data.type,
    title: data.title,
    category: data.category,
    description: data.description,
    imageUrl: data.imageUrl || null,
    building: data.building,
    locationDetails: data.locationDetails || '',
    lat: data.lat || null,
    lng: data.lng || null,
    ownerName: data.ownerName,
    ownerPhone: data.ownerPhone,
    ownerEmail: data.ownerEmail,
    status: 'pending',
    createdBy: data.createdBy || data.ownerEmail,
    createdAt: now,
    updatedAt: now
  };

  const docRef = await itemsCollection.add(newItem);
  const saved = await docRef.get();
  return { id: docRef.id, ...saved.data() };
}

async function getItems({ type, status } = {}) {
  let query = itemsCollection;

  if (type) query = query.where('type', '==', type);
  if (status) query = query.where('status', '==', status);

  const snapshot = await query.orderBy('createdAt', 'desc').get();
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}

async function getItemById(id) {
  const doc = await itemsCollection.doc(id).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
}

async function updateItem(id, updates) {
  updates.updatedAt = new Date();
  await itemsCollection.doc(id).update(updates);
  const updated = await itemsCollection.doc(id).get();
  return { id: updated.id, ...updated.data() };
}

async function deleteItem(id) {
  await itemsCollection.doc(id).delete();
}

module.exports = {
  createItem,
  getItems,
  getItemById,
  updateItem,
  deleteItem
};