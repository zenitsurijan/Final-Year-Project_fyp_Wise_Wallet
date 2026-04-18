import mongoose from "mongoose";
import User from "./models/User.js";
import Budget from "./models/Budget.js";

async function checkDb() {
    try {
        await mongoose.connect("mongodb://localhost:27017/auth_milestone");
        const users = await User.find({}, "email name").lean();
        const budgets = await Budget.find({}, "user_id family_id month type").lean();

        console.log("Users Found:", users.length);
        console.log("Budgets Found:", budgets.length);

        const indexes = await Budget.collection.indexes();
        console.log("Current Indexes:", JSON.stringify(indexes, null, 2));

        // Let's proactively drop the ones we know are problematic
        const problematicIndexes = [
            'user_1_category_1_month_1_year_1',
            'user_1_familyId_1_month_1_year_1',
            'user_1_family_id_1_month_1_year_1'
        ];

        for (const idxName of problematicIndexes) {
            if (indexes.find(i => i.name === idxName)) {
                console.log(`Dropping problematic index: ${idxName}...`);
                try {
                    await Budget.collection.dropIndex(idxName);
                    console.log(`Successfully dropped ${idxName}`);
                } catch (e) {
                    console.error(`Failed to drop ${idxName}:`, e.message);
                }
            }
        }

        // Also check if we can just sync indexes
        console.log("Syncing indexes with schema...");
        await Budget.syncIndexes();
        console.log("Indexes synced.");

        if (targetBudget) {
            console.log("- Budget Details:", JSON.stringify(targetBudget, null, 2));
        }
    } catch (error) {
        console.error("DB checking error:", error);
    } finally {
        await mongoose.disconnect();
    }
}

checkDb();
