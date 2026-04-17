#include <gtest/gtest.h>
#include "utils/SimTestBench.hpp"
#include "start.hpp"


class ExampleTest : public ::testing::Test
{
protected:
    // Test bench -- playground for everything
    SimTestBench  bench;

    // instance pointer for the device under test
    ExampleForwarder* example = nullptr;

    // Schematic ID of the device under test
    CircuitDescription::ChipId exampleCompId=0;
    
    void SetUp() override
    {
        // Register the circuit factory for plugins ExampleForwarder circuit
        bench.factory.loadLocalLibrary("test", std::make_unique<Foundry<ExampleForwarder>>());

        // load .cas/.sch files for the device under test 

        // <directory>, <namespace>, <filter by type>, <ignore .dll presence since we're using local foundry>
        bench.loader.loadFoundry(TEST_ASSETS_DIR, CS_PLUGIN_NAME, { ExampleForwarder::TYPE }, true);

        // enable writing so we can use driveWire() on this device
        exampleCompId = bench.addDevice(ExampleForwarder::TYPE, /*enableWriting=*/true);
        bench.build("fqn_of_the_test_schematic");

        example = bench.get<ExampleForwarder>(exampleCompId);
        ASSERT_NE(example, nullptr) << "ExampleForwarder instance not found";

        // Start with all pins low / released
        bench.driveWire(exampleCompId, "IN", W_Z);
        bench.settle();
    }
};


TEST_F(ExampleTest, TestForwarder)
{
    // start HIGH
	bench.driveWire(exampleCompId, "IN", W_HIGH);
    bench.settle();

    // go LOW
	bench.driveWire(exampleCompId, "IN", W_LOW);
    
    // 1 step
	bench.singleStep();
	EXPECT_EQ(bench.readWire(exampleCompId, "OUT"), W_HIGH) << "Expected OUT to hold its value after IN goes low for one step";
	EXPECT_TRUE(example->getState()) << "Expected internal state to reflect IN after one step";
	
	// 2 steps
	bench.singleStep();
	EXPECT_EQ(bench.readWire(exampleCompId, "OUT"), W_LOW) << "Expected OUT to reflect IN after two steps";
}
