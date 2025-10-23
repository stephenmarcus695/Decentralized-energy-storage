# Decentralized Energy Storage

A blockchain-based platform for coordinating home battery systems to balance grid demand and provide backup power services.

## Overview

This project creates a decentralized virtual power plant (VPP) by aggregating residential battery storage systems. Homeowners earn compensation by providing grid services during peak demand periods while maintaining backup power capabilities. The home battery market is valued at $20 billion with grid services compensation growing at 25% annually.

## Problem Statement

Traditional energy grid management faces several challenges:
- Peak demand periods strain grid infrastructure
- Centralized power plants are expensive to maintain
- Home battery systems are underutilized
- Complex intermediaries reduce homeowner compensation
- Limited coordination between distributed storage assets
- Lack of transparent settlement mechanisms

## Solution

Our decentralized energy storage coordination platform provides:
- **Real-time Battery Monitoring**: Track capacity levels across distributed home batteries
- **Automated Grid Services**: Coordinate energy dispatch during peak demand
- **Demand Response Management**: Participate in utility demand response programs
- **Fair Compensation**: Direct payments to homeowners without intermediaries
- **Backup Power Protection**: Maintain minimum charge levels for emergency use
- **Transparent Operations**: Blockchain-verified energy transactions

## Real-World Application

**50,000 Households Example**: A network of 50,000 homes with Tesla Powerwalls earning $30/month each by selling excess battery capacity during peak demand periods. The system automatically coordinates discharge during 4-8 PM peak hours while preserving 30% minimum charge for backup power. Annual household earnings: $360, network revenue: $18 million.

## Market Opportunity

- **Market Size**: $20 billion home battery market
- **Growth Rate**: 25% annual growth in grid services compensation
- **Target Users**: Homeowners with battery systems, utilities, grid operators
- **Revenue Model**: Transaction fees on energy services (2-5%)
- **Market Drivers**: Grid modernization, renewable integration, climate resilience

## Smart Contracts

### battery-capacity-optimizer

The core contract manages:
- Real-time battery level monitoring across the network
- Grid services provision coordination
- Demand response event participation
- Automated compensation distribution
- Minimum charge threshold enforcement
- Performance tracking and analytics
- Energy transaction settlement
- Battery health monitoring

## Technical Architecture

### Battery Integration
- IoT device authentication for smart batteries
- Real-time State of Charge (SoC) monitoring
- Discharge rate optimization
- Charge scheduling automation
- Emergency backup reservation

### Grid Services
- Peak demand response coordination
- Frequency regulation participation
- Voltage support services
- Load balancing optimization
- Real-time pricing integration

### Compensation Model
- Performance-based payments
- Availability incentives
- Energy delivered settlements
- Tiered reward structures
- Instant blockchain settlements

## Getting Started

### Prerequisites
- Clarinet CLI
- Stacks wallet
- Node.js (for testing)
- Compatible home battery system (Tesla Powerwall, Enphase, sonnen, etc.)

### Installation

```bash
# Clone the repository
git clone https://github.com/stephenmarcus695/Decentralized-energy-storage.git

# Navigate to project directory
cd Decentralized-energy-storage

# Install dependencies
npm install

# Run contract checks
clarinet check
```

### Testing

```bash
# Run all tests
npm test

# Run specific contract tests
clarinet test tests/battery-capacity-optimizer_test.ts
```

## Contract Functions

### Battery Management
- `register-battery`: Enroll home battery in the network
- `update-battery-level`: Report current charge state
- `set-minimum-reserve`: Configure backup power threshold
- `deactivate-battery`: Remove battery from grid services

### Grid Services
- `dispatch-energy`: Coordinate energy release during demand events
- `participate-demand-response`: Join utility DR programs
- `provide-frequency-regulation`: Support grid frequency stability
- `schedule-charging`: Optimize charging during low-cost periods

### Compensation
- `calculate-earnings`: Compute homeowner payments
- `distribute-compensation`: Execute payment settlements
- `claim-rewards`: Homeowners withdraw earnings
- `track-performance`: Monitor participation metrics

### Administration
- `set-service-rates`: Configure compensation rates (operator only)
- `update-grid-parameters`: Adjust dispatch thresholds
- `register-utility`: Add utility partners
- `set-settlement-schedule`: Configure payment frequency

### Read-Only Functions
- `get-battery-status`: Retrieve battery information
- `get-network-capacity`: Total available capacity
- `get-earnings-summary`: View homeowner earnings
- `get-dispatch-history`: Access energy transaction records
- `check-availability`: Verify battery eligibility for services

## Battery Requirements

### Compatible Systems
- **Tesla Powerwall**: 13.5 kWh capacity, 5 kW continuous power
- **Enphase IQ Battery**: 10.08 kWh capacity, 3.84 kW continuous power
- **sonnen eco**: 5-15 kWh capacity (modular), 3-8 kW power
- **LG Chem RESU**: 9.8-16 kWh capacity, 5 kW continuous power
- **Generac PWRcell**: 9-18 kWh capacity, 4.5-9 kW continuous power

### Technical Specifications
- Minimum capacity: 5 kWh
- Internet connectivity required
- Compatible inverter system
- Smart monitoring capability
- Remote control API access

## Compensation Structure

### Earnings Sources
1. **Availability Payments**: $5-10/month for network participation
2. **Energy Delivered**: $0.25-0.50 per kWh dispatched
3. **Demand Response Events**: $15-30 per event
4. **Frequency Regulation**: $0.10-0.20 per kWh of capacity
5. **Peak Shaving Bonuses**: $20-50 for high-impact events

### Typical Monthly Earnings
- **Basic Participation**: $5-15/month (availability only)
- **Active Participation**: $25-50/month (regular dispatch)
- **High Performance**: $50-100/month (frequent DR events)

## Security Considerations

- Battery authentication and authorization
- Minimum reserve enforcement (cannot discharge below safety threshold)
- Rate limiting on discharge requests
- Multi-signature controls for high-value transactions
- Emergency override capabilities
- Data encryption for home energy usage
- Privacy-preserving aggregation

## Grid Integration

### Utility Partnerships
- Demand response program integration
- Real-time pricing API connections
- Grid event notifications
- Settlement reconciliation
- Regulatory compliance reporting

### Safety Protocols
- Maximum discharge rate limits
- Temperature monitoring
- Cycle count tracking
- Health degradation detection
- Emergency disconnect procedures

## Roadmap

### Phase 1 (Current)
- Basic battery registration and monitoring
- Simple grid services coordination
- Manual compensation distribution

### Phase 2
- Automated demand response integration
- Real-time pricing optimization
- Advanced forecasting algorithms
- Mobile app for homeowners

### Phase 3
- Vehicle-to-Grid (V2G) integration
- Community microgrids
- Renewable energy trading
- Cross-utility coordination

## Environmental Impact

- **Grid Efficiency**: Reduce need for peaker plants (highest emissions)
- **Renewable Integration**: Enable higher solar/wind penetration
- **Load Balancing**: Smooth demand curves, reduce infrastructure stress
- **Resilience**: Provide community backup during outages
- **Carbon Reduction**: Estimated 2-5 tons CO2e per household annually

## Contributing

We welcome contributions from developers, energy professionals, and blockchain enthusiasts. Please read our contributing guidelines and submit pull requests.

## License

MIT License - see LICENSE file for details

## Contact & Support

- **GitHub**: [stephenmarcus695/Decentralized-energy-storage](https://github.com/stephenmarcus695/Decentralized-energy-storage)
- **Issues**: Report bugs and request features through GitHub Issues
- **Documentation**: Full API documentation available in `/docs`

## Acknowledgments

Built with Clarinet and the Stacks blockchain. Special thanks to the virtual power plant community and early battery network participants.

---

*Transforming home batteries into a distributed grid resource*
