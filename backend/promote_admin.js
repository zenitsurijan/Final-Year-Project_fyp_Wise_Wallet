import mongoose from 'mongoose';
import dotenv from 'dotenv';
import User from './models/User.js';

dotenv.config();

const email = process.argv[2];

if (!email) {
  console.error('Please provide an email address: node promote_admin.js <email>');
  process.exit(1);
}

async function promote() {
  try {
    console.log(`Connecting to database...`);
    await mongoose.connect(process.env.MONGO_URI);
    
    console.log(`Searching for user with email: ${email}`);
    const user = await User.findOneAndUpdate(
      { email: email.toLowerCase().trim() },
      { role: 'admin' },
      { new: true }
    );

    if (user) {
      console.log(`SUCCESS: User ${user.email} has been promoted to ADMIN.`);
    } else {
      console.error(`ERROR: User with email ${email} not found.`);
    }
  } catch (err) {
    console.error(`DATABASE ERROR: ${err.message}`);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

promote();
