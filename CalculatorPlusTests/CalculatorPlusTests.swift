import XCTest
@testable import CalculatorPlus

final class HPFinancialEngineTests: XCTestCase {

    var fin: HPFinancialEngine!

    override func setUp() { fin = HPFinancialEngine() }

    // MARK: - TVM

    func testTVM_PMT() {
        fin.tvmN = 360; fin.tvmI = 0.5; fin.tvmPV = -100_000; fin.tvmFV = 0
        fin.dispatch("PMT")
        XCTAssertEqual(fin.stack[0], 599.55, accuracy: 0.01)
    }

    func testTVM_PV() {
        fin.tvmN = 360; fin.tvmI = 0.5; fin.tvmPMT = -599.55; fin.tvmFV = 0
        fin.dispatch("PV")
        XCTAssertEqual(fin.stack[0], -100_000, accuracy: 1.0)
    }

    func testTVM_FV() {
        fin.tvmN = 12; fin.tvmI = 1; fin.tvmPV = -1000; fin.tvmPMT = 0
        fin.dispatch("FV")
        XCTAssertEqual(fin.stack[0], 1126.83, accuracy: 0.01)
    }

    func testTVM_N() {
        fin.tvmI = 1; fin.tvmPV = -1000; fin.tvmPMT = 0; fin.tvmFV = 1126.83
        fin.dispatch("n")
        XCTAssertEqual(fin.stack[0], 12, accuracy: 0.01)
    }

    func testTVM_I() {
        fin.tvmN = 12; fin.tvmPV = -1000; fin.tvmPMT = 0; fin.tvmFV = 1126.83
        fin.dispatch("i")
        XCTAssertEqual(fin.stack[0], 1.0, accuracy: 0.001)
    }

    // MARK: - Cash flows / NPV / IRR

    func testNPV_simple() {
        fin.tvmI = 10
        fin.dispatch("0"); fin.dispatch("CHS"); fin.dispatch("CF₀")   // CF0 = 0 (reset list)
        // Rebuild: CF0 = -100, CF1 = 110
        fin.cfCashFlows = [-100, 110]; fin.cfRepeatCounts = [1, 1]
        fin.dispatch("NPV")
        XCTAssertEqual(fin.stack[0], 0.0, accuracy: 0.001)
    }

    func testIRR_simple() {
        // CF0=-100, CF1=110 → IRR=10%
        fin.cfCashFlows = [-100, 110]; fin.cfRepeatCounts = [1, 1]
        fin.dispatch("IRR")
        XCTAssertEqual(fin.stack[0], 10.0, accuracy: 0.001)
    }

    func testNPV_multiperiod() {
        // CF0=-100, CF1=50, CF2=40, CF3=30 at 10% → NPV ≈ 1.05
        fin.tvmI = 10
        fin.cfCashFlows = [-100, 50, 40, 30]; fin.cfRepeatCounts = [1, 1, 1, 1]
        fin.dispatch("NPV")
        XCTAssertEqual(fin.stack[0], 1.05, accuracy: 0.1)
    }

    func testNPV_withRepeats() {
        // CF0=-100, CF1=30 × 3 periods, CF4=50 at 10%
        fin.tvmI = 10
        fin.cfCashFlows = [-100, 30, 50]; fin.cfRepeatCounts = [1, 3, 1]
        fin.dispatch("NPV")
        // NPV = -100 + 30/1.1 + 30/1.21 + 30/1.331 + 50/1.4641 ≈ -100+27.27+24.79+22.54+34.15 ≈ 8.75
        XCTAssertEqual(fin.stack[0], 8.75, accuracy: 0.1)
    }

    // MARK: - AMORT

    func testAMORT_firstPeriod() {
        // 60,000 mortgage at 0.75%/mo, PMT = -531.04, amortize 1 period
        fin.tvmPV = 60_000; fin.tvmI = 0.75; fin.tvmPMT = -531.04
        fin.stack[0] = 1
        fin.dispatch("AMORT")
        XCTAssertEqual(fin.stack[0], -450.0, accuracy: 0.01)   // interest
        XCTAssertEqual(fin.stack[1], -81.04, accuracy: 0.01)   // principal
        XCTAssertEqual(fin.tvmPV, 59_918.96, accuracy: 0.01)   // new balance
    }

    func testAMORT_interestPlusPrincipal_equalsPMT() {
        fin.tvmPV = 10_000; fin.tvmI = 1.0; fin.tvmPMT = -200
        fin.stack[0] = 6
        fin.dispatch("AMORT")
        let total = fin.stack[0] + fin.stack[1]  // interest + principal
        XCTAssertEqual(total, -200 * 6, accuracy: 0.01)
    }

    // MARK: - RND

    func testRND() {
        fin.stack[0] = 123.456789
        fin.dispatch("RND")
        XCTAssertEqual(fin.stack[0], 123.46, accuracy: 1e-9)
    }

    // MARK: - Simple interest (INT)

    func testSimpleInterest() {
        // PV=1000, i=12% annual, n=90 days → I = 1000*0.12*90/365 ≈ 29.59
        fin.tvmPV = 1000; fin.tvmI = 12; fin.tvmN = 90
        fin.dispatch("INT")
        XCTAssertEqual(fin.stack[0], 29.59, accuracy: 0.01)
        XCTAssertEqual(fin.stack[1], 1029.59, accuracy: 0.01)
    }

    // MARK: - Date arithmetic

    func testDATE_addDays() {
        // March 15 1990 + 30 days = April 14 1990
        fin.stack[1] = 3.151990   // Y = date
        fin.stack[0] = 30         // X = days
        fin.dispatch("DATE")
        // Expect 4.141990 in US format
        XCTAssertEqual(fin.stack[0], 4.141990, accuracy: 1e-6)
    }

    func testDeltaDays() {
        // March 15 1990 to April 14 1990 = 30 days
        fin.stack[1] = 3.151990
        fin.stack[0] = 4.141990
        fin.dispatch("ΔDAYS")
        XCTAssertEqual(fin.stack[0], 30, accuracy: 0)
    }

    // MARK: - EEX

    func testEEX_entry() {
        fin.dispatch("1"); fin.dispatch(".")
        fin.dispatch("5"); fin.dispatch("EEX")
        fin.dispatch("3")
        XCTAssertEqual(fin.stack[0], 1500, accuracy: 0)
    }

    func testEEX_negativeExponent() {
        fin.dispatch("1"); fin.dispatch(".")
        fin.dispatch("5"); fin.dispatch("EEX")
        fin.dispatch("3"); fin.dispatch("CHS")
        XCTAssertEqual(fin.stack[0], 0.0015, accuracy: 1e-10)
    }

    func testEEX_limitsTwoDigits() {
        fin.dispatch("1"); fin.dispatch("EEX")
        fin.dispatch("2"); fin.dispatch("3"); fin.dispatch("4")  // 4 should be rejected
        XCTAssertEqual(fin.stack[0], 1e23, accuracy: 0)
    }
}

final class HPScientificEngineTests: XCTestCase {

    var sci: HPScientificEngine!

    override func setUp() { sci = HPScientificEngine() }

    // MARK: - Trig

    func testSin() {
        sci.stack[0] = 30; sci.dispatch("SIN")
        XCTAssertEqual(sci.stack[0], 0.5, accuracy: 1e-10)
    }

    func testCos() {
        sci.stack[0] = 60; sci.dispatch("COS")
        XCTAssertEqual(sci.stack[0], 0.5, accuracy: 1e-10)
    }

    func testTan() {
        sci.stack[0] = 45; sci.dispatch("TAN")
        XCTAssertEqual(sci.stack[0], 1.0, accuracy: 1e-10)
    }

    // MARK: - HYP trig

    func testSinh() {
        sci.stack[0] = 1; sci.dispatch("SINH")
        XCTAssertEqual(sci.stack[0], sinh(1), accuracy: 1e-10)
    }

    func testCosh() {
        sci.stack[0] = 1; sci.dispatch("COSH")
        XCTAssertEqual(sci.stack[0], cosh(1), accuracy: 1e-10)
    }

    func testTanh() {
        sci.stack[0] = 1; sci.dispatch("TANH")
        XCTAssertEqual(sci.stack[0], tanh(1), accuracy: 1e-10)
    }

    func testSinhInverse() {
        let v = sinh(1.0)
        sci.stack[0] = v; sci.dispatch("SINH⁻¹")
        XCTAssertEqual(sci.stack[0], 1.0, accuracy: 1e-10)
    }

    func testCoshInverse() {
        sci.stack[0] = cosh(1.0); sci.dispatch("COSH⁻¹")
        XCTAssertEqual(sci.stack[0], 1.0, accuracy: 1e-10)
    }

    func testTanhInverse() {
        sci.stack[0] = tanh(0.5); sci.dispatch("TANH⁻¹")
        XCTAssertEqual(sci.stack[0], 0.5, accuracy: 1e-10)
    }

    func testCoshInverse_domainError() {
        sci.stack[0] = 0.5   // < 1, invalid
        sci.dispatch("COSH⁻¹")
        XCTAssertEqual(sci.displayText, "Error")
    }

    // MARK: - RAN#

    func testRanHash_inUnitInterval() {
        sci.dispatch("RAN#")
        XCTAssertGreaterThanOrEqual(sci.stack[0], 0)
        XCTAssertLessThan(sci.stack[0], 1)
    }

    func testSeed_reproducible() {
        sci.stack[0] = 0.5; sci.dispatch("SEED")
        sci.dispatch("RAN#"); let r1 = sci.stack[0]
        sci.stack[0] = 0.5; sci.dispatch("SEED")
        sci.dispatch("RAN#"); let r2 = sci.stack[0]
        XCTAssertEqual(r1, r2)
    }

    // MARK: - Unit conversions

    func testKmToMiles() {
        sci.stack[0] = 1; sci.dispatch("→mi")
        XCTAssertEqual(sci.stack[0], 0.6213711922, accuracy: 1e-6)
    }

    func testCelsiusToFahrenheit() {
        sci.stack[0] = 100; sci.dispatch("→°F")
        XCTAssertEqual(sci.stack[0], 212, accuracy: 1e-10)
    }

    func testFahrenheitToCelsius() {
        sci.stack[0] = 212; sci.dispatch("→°C")
        XCTAssertEqual(sci.stack[0], 100, accuracy: 1e-10)
    }

    // MARK: - Stats

    func testMean() {
        sci.stack[1] = 0; sci.stack[0] = 4; sci.dispatch("Σ+")
        sci.stack[1] = 0; sci.stack[0] = 6; sci.dispatch("Σ+")
        sci.dispatch("x̄")
        XCTAssertEqual(sci.stack[0], 5.0, accuracy: 1e-10)
    }
}
