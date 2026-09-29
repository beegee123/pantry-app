// Hard-coded sample data for step 2.
// The field names match the Supabase columns (snake_case) on purpose:
// in step 4 we swap this file for real data and nothing else has to change.

export const CATEGORY_ORDER = ['Dairy & eggs', 'Produce', 'Pantry', 'Frozen', 'Household']

export const sampleItems = [
  {
    id: '1',
    name: 'Eggs',
    category: 'Dairy & eggs',
    status: 'out',
    usual_amount: '1 dozen',
    stores: [], // no store linked → "Any store"
  },
  {
    id: '2',
    name: 'Milk',
    category: 'Dairy & eggs',
    status: 'low',
    usual_amount: '4 L',
    stores: [],
  },
  {
    id: '3',
    name: 'Rice, 8 kg',
    category: 'Pantry',
    status: 'out',
    usual_amount: '1 bag',
    stores: [{ name: 'Costco', is_preferred: true }],
  },
  {
    id: '4',
    name: 'Tomato paste',
    category: 'Pantry',
    status: 'out',
    usual_amount: '3 cans',
    stores: [{ name: 'No Frills', is_preferred: true }],
  },
  {
    id: '5',
    name: 'Olive oil',
    category: 'Pantry',
    status: 'in',
    usual_amount: '1 bottle',
    stores: [
      { name: 'Costco', is_preferred: true },
      { name: 'No Frills', is_preferred: false },
    ],
  },
  {
    id: '6',
    name: 'Toilet paper',
    category: 'Household',
    status: 'low',
    usual_amount: '1 pack of 30',
    stores: [{ name: 'Costco', is_preferred: true }],
  },
]
