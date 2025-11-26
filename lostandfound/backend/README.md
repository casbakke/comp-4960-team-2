# Lost & Found – Database Layer Documentation
Created by: Aliyan Hidayatallah  
Course: COMP-4960 – Software Engineering  
Role: Database Developer

---

## 📌 Overview
This folder contains all database logic for the Lost & Found system.  
The database uses **Google Firestore (Cloud Firestore, NoSQL)** and is accessed through a backend written in **Node.js**.

This module is responsible for:
- Creating new lost/found items
- Fetching items by status (lost or found)
- Storing metadata about items and contact information
- Providing Firestore data to the backend API team

---

## 📁 Folder Structure
backend/
firebase.js             → Initializes Firestore connection
itemRepository.js       → Contains all database CRUD functions
serviceAccountKey.json  → Firebase admin credentials
testDb.js               → Script to test database functionality
package.json            → Node dependencies

---

## 🔑 Firestore Schema

Collection: **`items`**

Each document looks like:
{
id: string,
type: ‘lost’ | ‘found’,
title: string,
category: string,
description: string,
imageUrl: string | null,
building: string,
locationDetails: string,
lat: number | null,
lng: number | null,
ownerName: string,
ownerPhone: string,
ownerEmail: string,
status: ‘pending’ | ‘resolved’,
createdBy: string,
createdAt: Timestamp,
updatedAt: Timestamp
}

Indexes created:
- Composite index on **type (asc)** + **createdAt (desc)**

---

## 🧪 Testing the Database

To test the database:

1. Install dependencies:
    npm install

2. Run the test script:
    node testDb.js

This script:
- Inserts a sample item
- Fetches all lost items
- Prints them in the console

If the database is connected properly, you will see output with item data and timestamps.

---

## 📦 Functions Available to Backend Team

### `createItem(item)`
Creates a new lost/found item.

### `getItems(type)`
Fetches items based on type:
- `"lost"` → returns all lost items
- `"found"` → returns all found items

Usage example:

```js
const repo = require('./itemRepository');

const items = await repo.getItems('lost');
console.log(items);

---

## 🚀 Integration Notes for Backend Teammates
### The backend API team can simply import:
    const { createItem, getItems } = require('./itemRepository');

### Then expose routes like:
    POST /api/items      → createItem()
    GET /api/items/lost  → getItems('lost')
    GET /api/items/found → getItems('found')