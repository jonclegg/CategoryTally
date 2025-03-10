# Tally

Tally is a simple expense tracking app that allows you to create categories for different types of expenses and track spending within each category.

## Features

- Create custom categories for different types of expenses (e.g., Groceries, Dining Out, Entertainment)
- Add expense items to each category with amounts and optional descriptions
- View a running total for each category
- All data is stored locally using JSON

## How to Use

1. **Home Screen**: When you first open the app, you'll see an empty home screen inviting you to create your first category.

2. **Creating Categories**: Tap the "+" button in the top right corner to create a new category. Enter a name for the category (e.g., "Groceries") and tap Save.

3. **Adding Expenses**: Tap on a category to view its details. Then tap the "+" button to add a new expense. Enter the amount spent and an optional description (e.g., "Randall's $25").

4. **Viewing Totals**: Each category shows a running total of all expenses. The detail view for a category shows all individual expenses along with the total at the top.

5. **Deleting Items**: Swipe left on any category or expense item to delete it.

## Implementation Details

- Built with SwiftUI
- Uses UserDefaults with JSON encoding for local data storage
- Follows MVVM architecture pattern 