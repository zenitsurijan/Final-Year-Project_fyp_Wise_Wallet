import mongoose from "mongoose";
import User from "./models/User.js";
import Budget from "./models/Budget.js";

async function fixBudgets() {
    try {
        await mongoose.connect("mongodb://localhost:27017/auth_milestone");
        console.log("Connected to MongoDB");

        const indexes = await Budget.collection.indexes();
        console.log("Total current indexes found:", indexes.length);

        for (const idx of indexes) {
            console.log(`- Index: ${idx.name} Keys: ${JSON.stringify(idx.key)}`);
        }

        const problematicNames = [
            'user_1_category_1_month_1_year_1',
            'user_1_familyId_1_month_1_year_1',
            'user_1_family_id_1_month_1_year_1'
        ];

        for (const name of problematicNames) {
            if (indexes.find(i => i.name === name)) {
                console.log(`ATTEMPTING TO DROP INDEX: ${name}`);
                try {
                    await Budget.collection.dropIndex(name);
                    console.log(`SUCCESSFULLY DROPPED: ${name}`);
                } catch (e) {
                    console.error(`FAILED TO DROP ${name}:`, e.message);
                }
            }
        }

        console.log("Running Budget.syncIndexes()...");
        const result = await Budget.syncIndexes();
        console.log("syncIndexes result:", JSON.stringify(result));

        const finalIndexes = await Budget.collection.indexes();
        console.log("Final indexes count:", finalIndexes.length);
        for (const idx of finalIndexes) {
            console.log(`- Final Index: ${idx.name}`);
        }

    } catch (error) {
        console.error("Critical error in fix script:", error);
    } finally {
        await mongoose.disconnect();
    }
}

fixBudgets();
