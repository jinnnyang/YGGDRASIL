# Futures and Margin Trading

Relevant source files

* [freqtrade/exchange/binance.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/binance.py)
* [freqtrade/exchange/exchange.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py)
* [freqtrade/exchange/kraken.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/kraken.py)
* [freqtrade/freqtradebot.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py)
* [freqtrade/persistence/migrations.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/migrations.py)
* [freqtrade/persistence/models.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/models.py)
* [freqtrade/persistence/trade\_model.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/trade_model.py)
* [tests/conftest.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/conftest.py)
* [tests/conftest\_trades.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/conftest_trades.py)
* [tests/exchange/test\_binance.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/exchange/test_binance.py)
* [tests/exchange/test\_exchange.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/exchange/test_exchange.py)
* [tests/exchange/test\_kraken.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/exchange/test_kraken.py)
* [tests/persistence/test\_persistence.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/persistence/test_persistence.py)

## Purpose and Scope

This page documents Freqtrade's futures and margin trading capabilities, covering:

* Trading mode configuration (`TradingMode.SPOT`, `TradingMode.MARGIN`, `TradingMode.FUTURES`)
* Margin mode selection (`MarginMode.NONE`, `MarginMode.ISOLATED`, `MarginMode.CROSS`)
* Leverage handling and position sizing
* Liquidation price calculation and monitoring
* Funding fee collection (futures perpetual contracts)
* Interest rate calculations (margin trading)
* Contract size conversions and precision handling

The implementation spans multiple modules: `FreqtradeBot` for orchestration, `Exchange` classes for exchange-specific logic, `Trade` model for persistence, and specialized modules in `freqtrade/leverage/` for calculations.

---

## Trading Modes and Margin Modes

Freqtrade supports three distinct trading modes with associated margin modes:

| Trading Mode | Margin Mode Options | Description |
| --- | --- | --- |
| `SPOT` | `NONE` | Traditional spot trading without leverage |
| `MARGIN` | `CROSS`, `ISOLATED` | Margin trading with borrowed funds |
| `FUTURES` | `CROSS`, `ISOLATED` | Perpetual futures contracts with leverage |

### Trading Mode Configuration

```mermaid
flowchart TD

Config["Configuration<br>config.json"]
TMEnum["TradingMode Enum<br>SPOT / MARGIN / FUTURES"]
MMEnum["MarginMode Enum<br>NONE / CROSS / ISOLATED"]
ExchangeInit["Exchange.init()<br>freqtrade/exchange/exchange.py:178-303"]
Validate["validate_trading_mode_and_margin_mode()<br>freqtrade/exchange/exchange.py:941-988"]
Supported["_supported_trading_mode_margin_pairs<br>Exchange subclass property"]
BinancePairs["[(SPOT,NONE),<br>(FUTURES,CROSS),<br>(FUTURES,ISOLATED)]"]
KrakenPairs["[(SPOT,NONE)]"]
CCXTConfig["_ccxt_config property<br>Sets defaultType"]
MarginType["options: {defaultType: 'margin'}"]
FuturesType["options: {defaultType: 'swap'}"]
SpotType["options: {}"]

Config --> TMEnum
Config --> MMEnum
TMEnum --> ExchangeInit
MMEnum --> ExchangeInit
ExchangeInit --> Validate
Validate --> Supported
Supported --> BinancePairs
Supported --> KrakenPairs
ExchangeInit --> CCXTConfig
CCXTConfig --> MarginType
CCXTConfig --> FuturesType
CCXTConfig --> SpotType
```

**Sources:**

* [freqtrade/exchange/exchange.py178-218](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L178-L218)
* [freqtrade/exchange/exchange.py411-418](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L411-L418)
* [freqtrade/exchange/binance.py70-75](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/binance.py#L70-L75)
* [freqtrade/exchange/kraken.py41-45](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/kraken.py#L41-L45)

---

## Core Leverage Properties

The trading mode is set during bot initialization and affects multiple system components:

```mermaid
flowchart TD

Bot["FreqtradeBot.init()<br>freqtrade/freqtradebot.py:79-188"]
TradingModeSet["self.trading_mode<br>self.margin_mode"]
Scheduler["Futures Scheduler<br>lines 159-172"]
UpdateFunding["update_funding_fees()<br>lines 367-378"]
UpdateLiq["update_all_liquidation_prices()<br>lines 357-365"]
TradeModel["Trade Model<br>persistence/trade_model.py"]
LevProps["Leverage Properties<br>lines 452-467"]
Fields["liquidation_price: float<br>is_short: bool<br>leverage: float<br>interest_rate: float<br>funding_fees: float"]

Bot --> TradingModeSet
TradingModeSet --> Scheduler
Scheduler --> UpdateFunding
Scheduler --> UpdateLiq
TradingModeSet --> TradeModel
TradeModel --> LevProps
LevProps --> Fields
```

**Sources:**

* [freqtrade/freqtradebot.py113-114](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L113-L114)
* [freqtrade/freqtradebot.py159-172](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L159-L172)
* [freqtrade/persistence/trade\_model.py452-467](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/trade_model.py#L452-L467)

---

## Leverage Configuration

### Leverage in Trade Execution

Leverage is configured per pair or globally and affects position sizing and margin requirements:

```
```
# Configuration example
"leverage": 3.0,
"max_leverage": 5.0,
"trading_mode": "futures",
"margin_mode": "isolated"
```
```

### Leverage Application

```mermaid
flowchart TD

Entry["execute_entry()<br>freqtrade/freqtradebot.py:863-1006"]
GetLeverage["get_valid_enter_price_and_stake()<br>lines 890-939"]
StratLev["strategy.leverage()<br>User-defined leverage"]
LevTiers["fill_leverage_tiers()<br>exchange.py:1603-1666"]
ValidateLev["validate_leverage()<br>Check against max_leverage"]
OrderParams["_get_params()<br>exchange.py:1857-1882"]
KrakenLev["params['leverage'] = round(leverage)"]
BinanceLev["Set in position mode"]
CreateOrder["create_order()<br>exchange.py:1379-1448"]
TradeObj["Trade object<br>trade.leverage = leverage"]

Entry --> GetLeverage
GetLeverage --> StratLev
StratLev --> LevTiers
LevTiers --> ValidateLev
ValidateLev --> OrderParams
OrderParams --> KrakenLev
OrderParams --> BinanceLev
OrderParams --> CreateOrder
CreateOrder --> TradeObj
```

**Sources:**

* [freqtrade/freqtradebot.py890-939](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L890-L939)
* [freqtrade/exchange/exchange.py1603-1666](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L1603-L1666)
* [freqtrade/exchange/kraken.py130-150](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/kraken.py#L130-L150)

---

## Position Types: Long and Short

### Long vs Short Trade Properties

The `is_short` flag fundamentally changes trade behavior:

| Property | Long (is\_short=False) | Short (is\_short=True) |
| --- | --- | --- |
| `entry_side` | `"buy"` | `"sell"` |
| `exit_side` | `"sell"` | `"buy"` |
| `trade_direction` | `"long"` | `"short"` |
| Borrowed | Quote currency (if leveraged) | Base currency |
| Profit direction | Price increase | Price decrease |
| Liquidation price | Below entry | Above entry |

### Borrowed Amount Calculation

```mermaid
flowchart TD

BorrowedProp["borrowed property<br>trade_model.py:492-503"]
CheckLev["has_no_leverage?<br>leverage == 1.0<br>and not is_short"]
Zero["return 0.0"]
CheckShort["is_short?"]
LongCalc["Borrowed = amount * open_rate<br>* (leverage - 1) / leverage"]
ShortCalc["Borrowed = amount"]
Example1["Example: 3x long<br>amount=30, open_rate=2.0<br>Borrowed = 302.0(3-1)/3 = 40 quote"]
Example2["Example: 3x short<br>amount=30<br>Borrowed = 30 base"]

BorrowedProp --> CheckLev
CheckLev --> Zero
CheckLev --> CheckShort
CheckShort --> LongCalc
CheckShort --> ShortCalc
LongCalc --> Example1
ShortCalc --> Example2
```

**Sources:**

* [freqtrade/persistence/trade\_model.py492-503](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/trade_model.py#L492-L503)
* [freqtrade/persistence/trade\_model.py546-565](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/trade_model.py#L546-L565)
* [tests/persistence/test\_persistence.py281-290](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/persistence/test_persistence.py#L281-L290)

---

## Liquidation Price Management

### Liquidation Price Calculation Flow

Diagram: Liquidation Price Update Sequence

```mermaid
sequenceDiagram
  participant FreqtradeBot
  participant liquidation_price.update_liquidation_prices
  participant Exchange
  participant Trade

  FreqtradeBot->>FreqtradeBot: startup()
  FreqtradeBot->>FreqtradeBot: freqtradebot.py:244
  loop [dry_run or not
    FreqtradeBot->>liquidation_price.update_liquidation_prices: update_all_liquidation_prices()
    liquidation_price.update_liquidation_prices->>Trade: freqtradebot.py:357-365
    liquidation_price.update_liquidation_prices->>Exchange: update_liquidation_prices(
    Exchange->>Exchange: exchange, wallets, stake_currency, dry_run)
    Exchange->>Exchange: Trade.get_open_trades()
    Exchange->>Exchange: get_or_calculate_liquidation_price(
    Exchange-->>liquidation_price.update_liquidation_prices: trade, open_trades)
    liquidation_price.update_liquidation_prices->>Trade: dry_run_liquidation_price(
    liquidation_price.update_liquidation_prices->>Trade: pair, open_rate, is_short,
  end
  note over FreqtradeBot: Scheduled via _schedule
```

**Sources:**

* [freqtrade/freqtradebot.py244](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L244-L244)
* [freqtrade/freqtradebot.py357-365](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L357-L365)
* [freqtrade/leverage/liquidation\_price.py7-150](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/leverage/liquidation_price.py#L7-L150)
* [freqtrade/exchange/exchange.py2091-2149](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L2091-L2149)

### Binance Liquidation Price Formula

For isolated margin mode:

```
Liquidation Price (Long) = 
    (WB - TMM + UPNL + cumB - cumQ) / (amount * (1 - mm_ratio))

Liquidation Price (Short) = 
    (WB - TMM + UPNL + cumB - cumQ) / (amount * (1 + mm_ratio))

Where:
- WB = Wallet Balance
- TMM = Total Maintenance Margin
- UPNL = Unrealized PNL
- cumB = Cumulative bid value
- cumQ = Cumulative ask value  
- mm_ratio = Maintenance margin ratio
```

For cross margin mode, additional calculations include other open positions.

**Sources:**

* [freqtrade/freqtradebot.py357-365](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L357-L365)
* [freqtrade/leverage/liquidation\_price.py1-150](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/leverage/liquidation_price.py#L1-L150)
* [freqtrade/exchange/binance.py290-383](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/binance.py#L290-L383)

### Stoploss vs Liquidation

```mermaid
flowchart TD

StopLoss["Trade.stoploss_or_liquidation<br>property<br>trade_model.py:469-476"]
HasLiq["liquidation_price<br>is set?"]
ReturnSL["return self.stop_loss"]
CheckShort["is_short?"]
MinCalc["return min(stop_loss,<br>liquidation_price)"]
MaxCalc["return max(stop_loss,<br>liquidation_price)"]
Usage["Used in exit checks<br>to prevent liquidation"]

StopLoss --> HasLiq
HasLiq --> ReturnSL
HasLiq --> CheckShort
CheckShort --> MinCalc
CheckShort --> MaxCalc
MinCalc --> Usage
MaxCalc --> Usage
```

**Sources:**

* [freqtrade/persistence/trade\_model.py469-476](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/trade_model.py#L469-L476)
* [tests/persistence/test\_persistence.py51-175](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/persistence/test_persistence.py#L51-L175)

---

## Funding Fees (Futures Trading)

Funding fees are periodic payments between long and short position holders in perpetual futures contracts.

### Funding Fee Update Mechanism

Diagram: Scheduled Funding Fee Updates via `schedule` Library

```mermaid
flowchart TD

Init["FreqtradeBot.init()"]
CheckFutures["trading_mode ==<br>TradingMode.FUTURES?"]
DefineUpdate["Define update() function<br>freqtradebot.py:161-164"]
Schedule["schedule.Scheduler<br>self._schedule<br>freqtradebot.py:157"]
TimeSlots["Schedule every day<br>at :01 and :31<br>for hours 0-23<br>freqtradebot.py:169-172"]
Process["Called in process()<br>freqtradebot.py:298"]
RunPending["_schedule.run_pending()"]
UpdateFunc["update_funding_fees()<br>freqtradebot.py:367-378"]
GetTrades["Trade.get_open_trades()"]
Loop["for trade in trades"]
ExchCall["exchange.get_funding_fees(<br>pair, amount,<br>is_short, open_date)"]
SetFees["trade.set_funding_fees(fees)"]

Init --> CheckFutures
CheckFutures --> DefineUpdate
DefineUpdate --> Schedule
Schedule --> TimeSlots
TimeSlots --> Process
Process --> RunPending
RunPending --> UpdateFunc
UpdateFunc --> GetTrades
GetTrades --> Loop
Loop --> ExchCall
ExchCall --> SetFees
```

**Sources:**

* [freqtrade/freqtradebot.py157-172](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L157-L172)
* [freqtrade/freqtradebot.py298](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L298-L298)
* [freqtrade/freqtradebot.py367-378](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L367-L378)

### Funding Fee Calculation

Diagram: Funding Fee Calculation Flow in `Exchange.get_funding_fees()`

```mermaid
flowchart TD

GetFees["Exchange.get_funding_fees()<br>exchange.py:2567-2645"]
CheckFunding["exchange.funding_fee_cutoff(<br>open_date)"]
AdjustDate["Adjust open_date forward"]
FetchDates["_get_funding_fee_dates_from_exchange()"]
RefreshOHLCV["refresh_latest_ohlcv(<br>candle_type=FUNDING_RATE)"]
GetData["_get_funding_fee_candles()"]
MergeData["merge_funding_and_mark_data()"]
CalcFunc["calculate_funding_fees(<br>df, amount, is_short)"]
SumRates["Σ (funding_rate *<br>mark_price * amount)"]
Direction["is_short?"]
Return["return fees"]
ReturnNeg["return -fees"]

GetFees --> CheckFunding
CheckFunding --> AdjustDate
CheckFunding --> FetchDates
AdjustDate --> FetchDates
FetchDates --> RefreshOHLCV
RefreshOHLCV --> GetData
GetData --> MergeData
MergeData --> CalcFunc
CalcFunc --> SumRates
SumRates --> Direction
Direction --> Return
Direction --> ReturnNeg
```

**Sources:**

* [freqtrade/exchange/exchange.py2567-2645](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L2567-L2645)
* [freqtrade/exchange/exchange.py2424-2472](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L2424-L2472)
* [freqtrade/exchange/exchange.py2474-2523](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L2474-L2523)

### Exchange-Specific Funding Implementation

**Binance:**

* Funding occurs every 8 hours (00:00, 08:00, 16:00 UTC)
* 15-second cutoff: trades opened at `XX:00:01` to `XX:00:14` are not charged until next period
* Implemented in `Binance.funding_fee_cutoff()` [freqtrade/exchange/binance.py260-269](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/binance.py#L260-L269)
* Uses `fetch_funding_rates()` for live rate data [freqtrade/exchange/binance.py271-290](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/binance.py#L271-L290)

**Kraken:**

* Requires `time_in_ratio` parameter (time spent in position within funding period)
* Raises `OperationalException` if `time_in_ratio` not provided [freqtrade/exchange/kraken.py175-177](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/kraken.py#L175-L177)
* Custom calculation per 4-hour periods [freqtrade/exchange/kraken.py151-184](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/kraken.py#L151-L184)

**Sources:**

* [freqtrade/exchange/binance.py260-269](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/binance.py#L260-L269)
* [freqtrade/exchange/binance.py271-290](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/binance.py#L271-L290)
* [freqtrade/exchange/kraken.py151-184](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/kraken.py#L151-L184)

---

## Interest Rates (Margin Trading)

Margin trading incurs interest on borrowed funds, calculated based on the borrowed amount and time held.

### Interest Calculation Flow

Diagram: `Trade.calculate_interest()` Logic

```mermaid
flowchart TD

CalcInt["Trade.calculate_interest()<br>trade_model.py:1186-1240"]
CheckMode["trading_mode ==<br>TradingMode.MARGIN?"]
Zero["return 0.0"]
CheckBorrowed["self.borrowed > 0?"]
CalcHours["hours =<br>(close_date or dt_now())<br>- open_date"]
GetRate["interest_rate<br>(daily rate)"]
CallInterest["interest.interest(<br>exchange_name,<br>borrowed, rate,<br>hours)"]
ExchSwitch["exchange"]
Binance["borrowed * rate<br>* hours / 24<br>interest.py:59-71"]
Kraken["borrowed * rate<br>* ceil((1+hours/4))<br>interest.py:73-88"]
Default["Return 0.0"]

CalcInt --> CheckMode
CheckMode --> Zero
CheckMode --> CheckBorrowed
CheckBorrowed --> Zero
CheckBorrowed --> CalcHours
CalcHours --> GetRate
GetRate --> CallInterest
CallInterest --> ExchSwitch
ExchSwitch --> Binance
ExchSwitch --> Kraken
ExchSwitch --> Default
```

**Sources:**

* [freqtrade/persistence/trade\_model.py1186-1240](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/trade_model.py#L1186-L1240)
* [freqtrade/leverage/interest.py44-88](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/leverage/interest.py#L44-L88)

### Interest Calculation Examples

From test cases [tests/persistence/test\_persistence.py177-279](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/persistence/test_persistence.py#L177-L279):

| Exchange | Leverage | Duration | Rate | Interest (Quote/Base) |
| --- | --- | --- | --- | --- |
| Binance | 3x long | 10 min | 0.0005 | 0.00083 quote |
| Binance | 3x short | 10 min | 0.0005 | 0.000625 base |
| Kraken | 3x long | 10 min | 0.0005 | 0.040 quote |
| Kraken | 3x short | 10 min | 0.0005 | 0.030 base |
| Binance | 5x long | 295 min | 0.0005 | 0.005 quote |

**Sources:**

* [freqtrade/persistence/trade\_model.py1186-1240](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/trade_model.py#L1186-L1240)
* [freqtrade/leverage/interest.py1-100](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/leverage/interest.py#L1-L100)
* [tests/persistence/test\_persistence.py177-279](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/persistence/test_persistence.py#L177-L279)

---

## Contract Sizes and Precision

Futures contracts often have contract sizes != 1, requiring conversion between contracts and amounts. For example, BTC/USDT:USDT on some exchanges has a contract size of 0.001 BTC per contract.

### Contract Size Handling

Diagram: Contract Size Conversion Flow

```mermaid
flowchart TD

GetSize["Exchange.get_contract_size(pair)<br>exchange.py:611-622"]
CheckMode["trading_mode ==<br>TradingMode.FUTURES?"]
Return1["return 1"]
GetMarket["market = markets.get(pair)"]
CheckMarket["market exists?"]
ReturnNone["return None"]
ExtractSize["contract_size = float(<br>market.get('contractSize', 1.0))"]
UsedBy["Used by conversion methods"]
Method1["_amount_to_contracts(pair, amount)<br>exchange.py:641-643"]
Method2["_contracts_to_amount(pair, contracts)<br>exchange.py:645-647"]
Method3["amount_to_contract_precision(pair, amount)<br>exchange.py:649-657"]
Util1["amount_to_contracts(amount, contract_size)<br>exchange_utils.py:119-130"]
Util2["contracts_to_amount(contracts, contract_size)<br>exchange_utils.py:133-144"]
Util3["amount_to_contract_precision(...)<br>exchange_utils.py:147-170"]

GetSize --> CheckMode
CheckMode --> Return1
CheckMode --> GetMarket
GetMarket --> CheckMarket
CheckMarket --> ReturnNone
CheckMarket --> ExtractSize
ExtractSize --> UsedBy
UsedBy --> Method1
UsedBy --> Method2
UsedBy --> Method3
Method1 --> Util1
Method2 --> Util2
Method3 --> Util3
```

**Sources:**

* [freqtrade/exchange/exchange.py611-622](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L611-L622)
* [freqtrade/exchange/exchange.py641-657](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L641-L657)
* [freqtrade/exchange/exchange\_utils.py119-170](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange_utils.py#L119-L170)

### Precision Handling

```mermaid
flowchart TD

Precision["amount_to_contract_precision()<br>exchange.py:648-656"]
GetProps["Get precision properties:<br>- amount_precision<br>- precisionMode<br>- contract_size"]
CallUtil["amount_to_contract_precision()<br>exchange_utils.py:147-170"]
Convert["amount / contract_size"]
Apply["amount_to_precision(<br>converted, precision,<br>precisionMode)"]
TICK_SIZE["precisionMode ==<br>TICK_SIZE?"]
RoundTick["Round to tick size"]
RoundDec["Round to decimals"]
Multiply["Unsupported markdown: list"]

Precision --> GetProps
GetProps --> CallUtil
CallUtil --> Convert
Convert --> Apply
Apply --> TICK_SIZE
TICK_SIZE --> RoundTick
TICK_SIZE --> RoundDec
RoundTick --> Multiply
RoundDec --> Multiply
```

**Sources:**

* [freqtrade/exchange/exchange.py610-622](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L610-L622)
* [freqtrade/exchange/exchange.py648-656](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L648-L656)
* [freqtrade/exchange/exchange\_utils.py147-170](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange_utils.py#L147-L170)

---

## Trade Model Adjustments for Leverage

### Profit Calculation Differences

The `Trade` model (and its backtesting counterpart `LocalTrade`) calculate profit with leverage, interest, and funding fees.

Diagram: `Trade.calc_profit()` and `Trade.calc_profit_ratio()` Flow

```mermaid
flowchart TD

CalcProfit["Trade.calc_profit(rate, amount, open_rate)<br>trade_model.py:913-987"]
CalcInterest["interest = calculate_interest()<br>For margin trading"]
GetFunding["funding_fees = self.funding_fees or 0<br>For futures trading"]
CalcBase["Base calculation"]
CheckShort["is_short?"]
LongCalc["close_value = amount * rate<br>profit = close_value - open_trade_value<br>- total_fees - interest - funding_fees"]
ShortCalc["close_value = amount * rate<br>profit = open_trade_value - close_value<br>- total_fees - interest - funding_fees"]
Return["Return profit in stake currency"]
CalcRatio["calc_profit_ratio(rate, ...)<br>trade_model.py:989-1027"]
Ratio["profit_ratio = profit /<br>total_stake_amount()"]

CalcProfit --> CalcInterest
CalcProfit --> GetFunding
CalcInterest --> CalcBase
GetFunding --> CalcBase
CalcBase --> CheckShort
CheckShort --> LongCalc
CheckShort --> ShortCalc
LongCalc --> Return
ShortCalc --> Return
Return --> CalcRatio
CalcRatio --> Ratio
```

**Sources:**

* [freqtrade/persistence/trade\_model.py913-987](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/trade_model.py#L913-L987)
* [freqtrade/persistence/trade\_model.py989-1027](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/trade_model.py#L989-L1027)
* [freqtrade/persistence/trade\_model.py826-863](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/trade_model.py#L826-L863)

### Open Trade Value

```mermaid
flowchart TD

OpenValue["_calc_open_trade_value()<br>trade_model.py:826-863"]
CheckShort["is_short?"]
LongValue["open_value = amount<br>* open_rate<br>/ leverage"]
ShortValue["open_value = amount<br>* open_rate<br>* (leverage + 1)<br>/ leverage"]
AddFee["Unsupported markdown: list"]
Example1["Example Long 3x:<br>amount=30, open_rate=2.0<br>value = 30*2.0/3 = 20"]
Example2["Example Short 3x:<br>amount=30, open_rate=2.0<br>value = 302.04/3 = 80"]

OpenValue --> CheckShort
CheckShort --> LongValue
CheckShort --> ShortValue
LongValue --> AddFee
ShortValue --> AddFee
AddFee --> Example1
AddFee --> Example2
```

**Sources:**

* [freqtrade/persistence/trade\_model.py826-863](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/trade_model.py#L826-L863)
* [freqtrade/persistence/trade\_model.py913-987](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/trade_model.py#L913-L987)

---

## Liquidation and Stoploss Monitoring

### Position Monitoring in `exit_positions()`

The bot continuously monitors positions for stoploss and liquidation conditions. The `stoploss_or_liquidation` property ensures the bot exits before liquidation occurs.

Diagram: Exit Position Monitoring Flow

```mermaid
flowchart TD

Process["FreqtradeBot.process()<br>freqtradebot.py:247-301"]
ExitPos["exit_positions(trades)<br>freqtradebot.py:1614-1692"]
Loop["for trade in trades"]
FullyOpen["trade.has_open_position?"]
Skip["Skip (order not filled)"]
GetRates["exchange.get_rates(pair, True, is_short)"]
CalcStopLoss["Trade.adjust_stop_loss(rate, stoploss_pct)<br>Updates stop_loss if trailing"]
GetEffective["effective_sl = trade.stoploss_or_liquidation<br>trade_model.py:469-476"]
Compare["For long: rate <= effective_sl<br>For short: rate >= effective_sl"]
CheckReason["effective_sl ==<br>liquidation_price?"]
Continue["Continue to ROI/custom checks"]
ExitLiq["execute_trade_exit(<br>exit_reason='liquidation')"]
ExitSL["execute_trade_exit(<br>exit_reason='stop_loss')"]

Process --> ExitPos
ExitPos --> Loop
Loop --> FullyOpen
FullyOpen --> Skip
FullyOpen --> GetRates
GetRates --> CalcStopLoss
CalcStopLoss --> GetEffective
GetEffective --> Compare
Compare --> CheckReason
Compare --> Continue
CheckReason --> ExitLiq
CheckReason --> ExitSL
```

**Sources:**

* [freqtrade/freqtradebot.py1614-1692](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L1614-L1692)
* [freqtrade/persistence/trade\_model.py469-476](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/trade_model.py#L469-L476)
* [freqtrade/freqtradebot.py1522-1612](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L1522-L1612)

### Cross Margin Risk

In cross margin mode (`MarginMode.CROSS`), all positions share the same margin balance. The liquidation price of one position depends on the unrealized PNL and maintenance margin of all other positions.

Diagram: Cross Margin Liquidation Price Dependencies

```mermaid
flowchart TD

Wallet["Cross Margin Wallet<br>Total Balance"]
Pos1["Position 1: BTC/USDT<br>open_rate, amount, leverage"]
Pos2["Position 2: ETH/USDT<br>open_rate, amount, leverage"]
Pos3["Position 3: XRP/USDT<br>open_rate, amount, leverage"]
LiqCalc["Liquidation Price Calculation<br>for Position 1"]
Variables["Variables from other positions:<br>mm_ex_1 = Σ maintenance_margini<br>upnl_ex_1 = Σ unrealized_pnli<br>(for i != current position)"]
Formula["Binance formula:<br>Liq Price = (WB - TMM + UPNL + cumB - cumQ)<br>/ (amount * (1 ± mm_ratio))"]
Implementation["Binance.dry_run_liquidation_price()<br>binance.py:292-383"]
Updates["Updated via scheduler<br>every ~30 min<br>freqtradebot.py:163"]

Wallet --> Pos1
Wallet --> Pos2
Wallet --> Pos3
Pos1 --> LiqCalc
Pos2 --> LiqCalc
Pos3 --> LiqCalc
LiqCalc --> Variables
Variables --> Formula
Formula --> Implementation
Implementation --> Updates
```

**Sources:**

* [freqtrade/exchange/binance.py292-383](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/binance.py#L292-L383)
* [freqtrade/freqtradebot.py357-365](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L357-L365)
* [freqtrade/leverage/liquidation\_price.py7-150](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/leverage/liquidation_price.py#L7-L150)

---

## Exchange-Specific Implementations

### Binance Futures

**Initialization checks** [freqtrade/exchange/binance.py110-146](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/binance.py#L110-L146):

* Verifies dual side position mode is disabled (hedge mode not supported)
* Checks multi-asset margin mode (only for cross margin)

**Configuration:**

```
```
{
    "exchange": {
        "name": "binance",
    },
    "trading_mode": "futures",
    "margin_mode": "isolated",  # or "cross"
    "liquidation_buffer": 0.05  # 5% buffer
}
```
```

**Supported features:**

* Both isolated and cross margin
* Liquidation price from API or calculated
* Mark price for stop orders
* Proxy coin for cross margin collateral

### Kraken Margin/Futures

**Limitations** [freqtrade/exchange/kraken.py41-45](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/kraken.py#L41-L45):

* Limited futures/margin support
* Requires `time_in_ratio` for funding calculations
* Leverage set in order parameters, not position mode

**Leverage setting** [freqtrade/exchange/kraken.py130-150](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/kraken.py#L130-L150):

```
```
def _get_params(self, side, ordertype, leverage, ...):
    params = super()._get_params(...)
    if leverage > 1.0:
        params["leverage"] = round(leverage)
    return params
```
```

### Supported Trading Mode Matrix

This table reflects the `_supported_trading_mode_margin_pairs` property defined in each exchange class:

| Exchange | SPOT | MARGIN | FUTURES (Cross) | FUTURES (Isolated) |
| --- | --- | --- | --- | --- |
| Binance | ✓ | ✗ | ✓ | ✓ |
| Bybit | ✓ | ✗ | ✓ | ✓ |
| OKX | ✓ | ✗ | ✓ | ✓ |
| Kraken | ✓ | ✗ | ✗ | ✗ |
| Gate.io | ✓ | ✗ | ✓ | ✓ |

The base `Exchange` class defaults to only `(TradingMode.SPOT, MarginMode.NONE)` at [freqtrade/exchange/exchange.py174-177](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L174-L177)

**Sources:**

* [freqtrade/exchange/exchange.py174-177](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L174-L177)
* [freqtrade/exchange/binance.py72-77](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/binance.py#L72-L77)
* [freqtrade/exchange/kraken.py40-44](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/kraken.py#L40-L44)

---

## Configuration Example

Complete configuration for futures trading:

```
```
{
    "trading_mode": "futures",
    "margin_mode": "isolated",
    "liquidation_buffer": 0.05,
    
    "stake_currency": "USDT",
    "stake_amount": "unlimited",
    
    "exchange": {
        "name": "binance",
        "ccxt_config": {},
        "ccxt_async_config": {}
    },
    
    "leverage": 3.0,
    
    "order_types": {
        "entry": "limit",
        "exit": "limit",
        "stoploss": "market",
        "stoploss_on_exchange": true
    }
}
```
```

**Key Configuration Parameters:**

* `trading_mode`: `"spot"`, `"margin"`, or `"futures"`
* `margin_mode`: `"isolated"` or `"cross"`
* `liquidation_buffer`: Percentage buffer before liquidation (default: 0.05 = 5%)
* `leverage`: Default leverage (can be overridden in strategy)

**Sources:**

* [freqtrade/freqtradebot.py113-114](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L113-L114)
* [freqtrade/exchange/exchange.py205-218](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L205-L218)

---

## Database Schema Changes

Leverage-related fields in the `trades` table:

| Column | Type | Description |
| --- | --- | --- |
| `trading_mode` | String | SPOT, MARGIN, or FUTURES |
| `leverage` | Float | Leverage multiplier (default: 1.0) |
| `is_short` | Boolean | True for short positions |
| `liquidation_price` | Float | Calculated liquidation price |
| `interest_rate` | Float | Daily interest rate for margin |
| `funding_fees` | Float | Accumulated funding fees |
| `funding_fee_running` | Float | Running funding fees (internal) |

**Migration:** [freqtrade/persistence/migrations.py109-127](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/migrations.py#L109-L127)

**Sources:**

* [freqtrade/persistence/trade\_model.py452-467](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/trade_model.py#L452-L467)
* [freqtrade/persistence/migrations.py109-127](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/persistence/migrations.py#L109-L127)