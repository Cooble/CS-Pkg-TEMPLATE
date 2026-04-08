#pragma once
#include <cs_plugin_api.h>
#include <sim/ICircuitFoundry.hpp>
#include <signature.hpp>
#include <sim/Circuit.hpp>


#define EXAMPLES "EXAMPLES/"

class ExampleComponent : public sim::Circuit
{

public:
    CIRCUIT_TYPE(EXAMPLES "FORWARDER")
#include CIRCUIT_PINS(FORWARDER)

    void solder(std::span<sim::PinState* const> pins_write, std::span<const sim::PinState* const> pins_read, const std::vector<std::string>& pinNames) override;
    
    bool step(bool) override;
    bool drawWindow() override;

    void save(nlohmann::json&) const override;
    void load(const nlohmann::json&) override;


private:
	bool m_breakpoint_active = false;
};


class ExampleFoundry : public sim::Foundry<ExampleComponent>
{
public:
    // called when dll is loaded
    void initialize() override;
};

EXPORT_CIRCUIT_FOUNDRY(ExampleFoundry);