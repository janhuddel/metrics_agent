# Metrics Agent

A high-performance Elixir-based metrics collection agent designed to work seamlessly with Telegraf's `inputs.execd` plugin. The agent collects metrics from various sources and outputs them in InfluxDB Line Protocol format to stdout, making it perfect for integration with monitoring systems.

## Core Functionality

The Metrics Agent is a modular system that:

- **Collects metrics** from multiple sources (currently Tasmota devices via MQTT and demo data)
- **Serializes metrics** to InfluxDB Line Protocol format
- **Outputs to stdout** for easy integration with Telegraf's `inputs.execd`
- **Logs to stderr** to maintain clean separation of metrics and log data
- **Provides fault tolerance** with supervisor-based process management
- **Supports hot configuration** through environment variables

### Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Tasmota       │    │   Demo Module    │    │  Other Modules  │
│   (MQTT)        │    │   (Test Data)    │    │   (Future)      │
└─────────┬───────┘    └─────────┬────────┘    └─────────┬───────┘
          │                      │                       │
          └──────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │   Module Supervisor       │
                    │   (Process Management)    │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │   Metrics Collector       │
                    │   (Line Protocol Output)  │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │        stdout             │
                    │   (Telegraf input)        │
                    └───────────────────────────┘
```

## Quick Start

### Development

```bash
# Clone the repository
git clone https://github.com/your-username/metrics_agent.git
cd metrics_agent

# Install dependencies
make deps

# Run in development mode
make dev

# Run tests
make test
```

## Production Deployment

### Automated Installation

The easiest way to deploy the Metrics Agent is using the provided installation script:

```bash
curl -fsSL https://raw.githubusercontent.com/your-username/metrics_agent/main/scripts/install.sh | sudo bash
```

This script will:
- Download the latest release
- Install following Linux FHS standards
- Create the `telegraf` user and group
- Configure environment files

### Verify Installation

Run the test script to verify everything is working:

```bash
sudo /opt/metrics-agent/scripts/test-installation.sh
```

### Manual Installation

If you prefer manual installation:

1. **Download the latest release**:
   ```bash
   wget https://github.com/your-username/metrics_agent/releases/latest/download/metrics_agent.tar.gz
   tar -xzf metrics_agent.tar.gz
   ```

2. **Install following Linux FHS**:
   ```bash
   # Create directories
   sudo mkdir -p /opt/metrics-agent
   sudo mkdir -p /etc/metrics-agent
   sudo mkdir -p /var/log/metrics-agent

   # Copy application
   sudo cp -r metrics_agent/* /opt/metrics-agent/

   # Copy configuration files
   sudo cp scripts/telegraf-example.conf /etc/metrics-agent/
   ```

3. **Set Permissions**:
   ```bash
   # Create telegraf user if it doesn't exist
   sudo useradd --system --no-create-home --shell /bin/false telegraf || true

   # Set ownership
   sudo chown -R telegraf:telegraf /opt/metrics-agent
   sudo chown -R telegraf:telegraf /var/log/metrics-agent
   sudo chown -R telegraf:telegraf /etc/metrics-agent

   # Set permissions
   sudo chmod 755 /opt/metrics-agent
   sudo chmod 755 /opt/metrics-agent/bin
   sudo chmod 755 /opt/metrics-agent/bin/metrics_agent
   ```

## Telegraf Integration

The Metrics Agent is designed to work with Telegraf's `inputs.execd` plugin. Add the following configuration to your `telegraf.conf`:

```toml
[[inputs.execd]]
  command = ["/opt/metrics-agent/bin/metrics_agent", "start"]
  signal = "STDIN"
  restart_delay = "10s"
  data_format = "influx"
```

### Process Chain

The recommended production setup follows this process chain:

```
systemd → telegraf (inputs.execd) → metrics_agent
```

1. **systemd** manages the Telegraf service
2. **Telegraf** runs the metrics agent via `inputs.execd` (no separate systemd service needed for metrics_agent)
3. **metrics_agent** outputs metrics to stdout (consumed by Telegraf)

### Configure Module Settings

Edit the TOML configuration:

```bash
sudo nano /etc/metrics-agent/config.toml
```

Update the module settings:

```toml
[modules.tasmota]
enabled = true
mqtt_host = "your-mqtt-broker.com"
mqtt_port = 1883
discovery_topic = "tasmota/discovery/+/config"
```

### Start Telegraf

```bash
# Restart Telegraf to pick up the new configuration
sudo systemctl restart telegraf
```

## Configuration

### TOML Configuration

The agent uses TOML files for configuration, providing a structured and scalable approach to managing module settings and device-specific overrides.

### File Locations (Linux FHS)

Following the Linux Filesystem Hierarchy Standard:

| Component | Location | Purpose |
|-----------|----------|---------|
| **Application** | `/opt/metrics-agent/` | Main application files |
| **Configuration** | `/etc/metrics-agent/` | Configuration files |
| **Logs** | `/var/log/metrics-agent/` | Application logs |
| **User** | `telegraf` | Dedicated system user |

### Configuration Files

- **Main configuration**: `/etc/metrics-agent/config.toml`
- **Example configuration**: `config/config.toml.example`

### TOML Configuration Structure

The configuration file supports a hierarchical structure with module-specific settings and device overrides:

```toml
# Demo module configuration
[modules.demo]
enabled = true
interval = 1000
vendor = "demo"

# Tasmota module configuration
[modules.tasmota]
enabled = true
mqtt_host = "localhost"
mqtt_port = 1883
discovery_topic = "tasmota/discovery/+/config"
client_id = ""  # Leave empty for auto-generation

# Device-specific overrides for Tasmota module
[modules.tasmota.devices."device1"]
mqtt_host = "192.168.1.100"
discovery_topic = "custom/device1/discovery/+/config"
custom_settings = { timeout = 30, retry_count = 3 }

[modules.tasmota.devices."device2"]
mqtt_host = "192.168.1.101"
mqtt_port = 8883
discovery_topic = "secure/device2/discovery/+/config"
custom_settings = { timeout = 60, retry_count = 5, ssl = true }
```

### Configuration Features

- **Module-based configuration**: Each module has its own configuration section
- **Device overrides**: Override global module settings for specific devices
- **Hierarchical structure**: Clean separation of concerns
- **Type safety**: TOML provides better type handling than environment variables
- **Extensibility**: Easy to add new modules and configuration options

### Module Configuration

| Module | Configuration Section | Key Settings |
|--------|----------------------|--------------|
| **Demo** | `[modules.demo]` | `enabled`, `interval`, `vendor` |
| **Tasmota** | `[modules.tasmota]` | `enabled`, `mqtt_host`, `mqtt_port`, `discovery_topic` |

### Device Overrides

Device-specific overrides are defined under `[modules.<module>.devices."<device_id>"]` and will override the global module settings for that specific device. This allows for:

- Different MQTT brokers per device
- Custom discovery topics
- Device-specific timeouts and retry settings
- SSL/TLS configurations per device

## Monitoring and Maintenance

### Service Management

Since the metrics agent runs under Telegraf's `inputs.execd`, manage it through Telegraf:

```bash
# Check Telegraf status
sudo systemctl status telegraf

# View Telegraf logs (includes metrics_agent output)
sudo journalctl -u telegraf -f

# Restart Telegraf (will restart metrics_agent)
sudo systemctl restart telegraf

# Stop Telegraf
sudo systemctl stop telegraf
```

### Log Analysis

```bash
# View recent logs
sudo journalctl -u telegraf -n 100

# Follow logs in real-time
sudo journalctl -u telegraf -f

# View logs from specific time
sudo journalctl -u telegraf --since "1 hour ago"
```

### Testing

```bash
# Test manual execution
sudo -u telegraf /opt/metrics-agent/bin/metrics_agent start

# Test with different environment
sudo -u telegraf MIX_ENV=dev /opt/metrics-agent/bin/metrics_agent start
```

### Log Locations

- **Telegraf logs**: `journalctl -u telegraf` (includes metrics_agent stderr output)
- **Metrics output**: stdout (consumed by Telegraf)
- **Error logs**: stderr (via Telegraf's systemd journal)

## Development

### Project Structure

```
lib/
├── metrics_agent/
│   ├── application.ex          # Main application module
│   ├── metrics_collector.ex    # Metrics serialization and output
│   └── modules/
│       ├── module_supervisor.ex # Module process management
│       ├── demo/
│       │   └── demo.ex         # Demo/test metrics module
│       └── tasmota/
│           ├── tasmota.ex      # Tasmota MQTT client
│           └── message_handler.ex # MQTT message processing
```

### Building Releases

```bash
# Create a release
make release

# Test the release
_build/prod/rel/metrics_agent/bin/metrics_agent start
```

### Adding New Modules

1. Create a new module in `lib/metrics_agent/modules/your_module/`
2. Implement the GenServer behavior
3. Add the module to `ModuleSupervisor` children list
4. Configure the module in `config/config.exs`

## Troubleshooting

### Common Issues

1. **Telegraf service issues**:
   ```bash
   sudo journalctl -u telegraf -n 50
   sudo systemctl status telegraf
   ```

2. **Permission denied**:
   ```bash
   ls -la /opt/metrics-agent/bin/metrics_agent
   sudo chown telegraf:telegraf /opt/metrics-agent/bin/metrics_agent
   sudo chmod 755 /opt/metrics-agent/bin/metrics_agent
   ```

3. **No metrics output**:
   ```bash
   # Test manual execution
   sudo -u telegraf /opt/metrics-agent/bin/metrics_agent start
   
   # Check Telegraf configuration
   sudo telegraf --test --config /etc/telegraf/telegraf.conf
   ```

4. **MQTT connection issues**:
   ```bash
   # Test MQTT connectivity
   mosquitto_pub -h your-mqtt-host -t test/topic -m "test message"
   
   # Check environment variables
   sudo -u telegraf env | grep MQTT
   ```

5. **High CPU usage**:
   - Check for panic trigger files: `/tmp/metrics-agent-panic-*`
   - Review module intervals in configuration

### Debug Mode

Run in debug mode for detailed logging:

```bash
sudo -u telegraf MIX_ENV=dev /opt/metrics-agent/bin/metrics_agent start
```

## Updates

To update to a newer version:

1. **Run the install script again**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/your-username/metrics_agent/main/scripts/install.sh | sudo bash
   ```

2. **Restart Telegraf to pick up the new version**:
   ```bash
   sudo systemctl restart telegraf
   ```

## Security Considerations

- The application runs as the `telegraf` user (non-root)
- Configuration files are readable only by the `telegraf` user
- MQTT credentials should be configured securely
- Regular updates are recommended for security patches

## Performance Tuning

- Adjust log levels in production (`:info` instead of `:debug`)
- Monitor memory usage with `systemctl status telegraf`
- Consider adjusting MQTT keepalive settings for your network
- Use appropriate intervals for metric collection modules

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

