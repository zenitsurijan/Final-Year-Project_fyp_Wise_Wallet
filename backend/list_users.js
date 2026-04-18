import mongoose from 'mongoose';
import User from './models/User.js';
import dotenv from 'dotenv';
dotenv.config();

mongoose.connect(process.env.MONGO_URI).then(async () => {
    const users = await User.find({}, 'name email role isVerified');
    console.log(JSON.stringify(users, null, 2));
    process.exit(0);
});
