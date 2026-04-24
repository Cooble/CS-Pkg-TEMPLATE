#pragma once
#include <cs_plugin_api.h>
#include <sim/ICircuitFoundry.hpp>
#include <signature.hpp>
#include <sim/Circuit.hpp>
#include "PluginExamplePlugin.h"

#define EXAMPLES "EXAMPLES/"

class CS_PLUGIN_API ExampleForwarder : public sim::Circuit
{
public:
    CIRCUIT_TYPE(EXAMPLES "FORWARDER")
#include CIRCUIT_PINS(FORWARDER)
    void solder(std::span<sim::PinState* const> pins_write, std::span<const sim::PinState* const> pins_read, double freq) override;
    
    bool step(bool) override;
    bool drawWindow() override;

    void save(nlohmann::json&) const override;
    void load(const nlohmann::json&) override;

    bool getState()const{
        return m_state;
	}


private:
	bool m_breakpoint_active = false;
    bool m_state{};
};


class ExampleFoundry : public sim::Foundry<ExampleForwarder>
{
public:
    // called when dll is loaded
    void initialize() override;
};

