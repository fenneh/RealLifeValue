# RealLifeValue

RealLifeValue is a World of Warcraft addon that converts in-game gold and item prices to real-world currency values based on current WoW Token prices. It helps players understand the real-money value of their in-game wealth and items.

## Features

- Displays real-money values in tooltips for items
- Supports multiple currencies (GBP, EUR, USD)
- Shows both individual item values and stack values
- Integrates with popular auction addons:
  - Auctionator
  - TheUndermineJournal
- Provides commands to check your character's total gold value in real currency
- User-friendly settings interface
- Automatic WoW Token price updates

## Installation

1. Download the latest version of RealLifeValue
2. Extract the folder into your World of Warcraft `Interface/AddOns` directory
3. Ensure the folder is named exactly `RealLifeValue`
4. Restart World of Warcraft if it's running

## Usage

### Basic Commands

- `/rlvalue` - Opens the settings interface
- `/myrlvalue` - Shows the real-money value of your current gold

### Settings

Access the settings panel using `/rlvalue` to:
- Choose your preferred currency (GBP, EUR, USD)
- View current WoW Token prices
- Customize the display settings

### Tooltip Integration

The addon automatically adds real-money values to item tooltips showing:
- Individual item value
- Stack value (for stackable items)
- Price source (Auctionator, UnderMineJournal, or Vendor)

## Dependencies

### Required
- None

### Optional
- Auctionator (for more accurate auction house prices)
- TheUndermineJournal (for additional price data)

## Known Issues

- Token prices may show as "Updating..." briefly after logging in while fresh data is fetched
- Price conversions depend on current WoW Token prices being available

## Contributing

Feel free to submit issues and enhancement requests via the GitHub issue tracker.