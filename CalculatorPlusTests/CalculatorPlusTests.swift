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
        // PMT=-599.55 (outflow) with these params → PV is positive (cash received)
        fin.tvmN = 360; fin.tvmI = 0.5; fin.tvmPMT = -599.55; fin.tvmFV = 0
        fin.dispatch("PV")
        XCTAssertEqual(fin.stack[0], 100_000, accuracy: 1.0)
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
        XCTAssertEqual(sci.stack[0], 1.0 / 1.609344, accuracy: 1e-6)
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

    // MARK: - LSTx

    func testLSTx_afterUnary() {
        sci.stack[0] = 3
        sci.dispatch("x²")          // lastX = 3
        sci.dispatch("LSTx")
        XCTAssertEqual(sci.stack[0], 3.0, accuracy: 1e-10)
    }

    func testLSTx_afterBinary() {
        sci.stack[1] = 10; sci.stack[0] = 4
        sci.dispatch("+")           // lastX = 4 (X before +)
        sci.dispatch("LSTx")
        XCTAssertEqual(sci.stack[0], 4.0, accuracy: 1e-10)
    }

    // MARK: - Percent

    func testPercent() {
        sci.stack[1] = 200; sci.stack[0] = 15
        sci.dispatch("%")
        XCTAssertEqual(sci.stack[0], 30.0, accuracy: 1e-10)
    }

    func testDeltaPercent() {
        sci.stack[1] = 100; sci.stack[0] = 125
        sci.dispatch("Δ%")
        XCTAssertEqual(sci.stack[0], 25.0, accuracy: 1e-10)
    }

    // MARK: - Angle value conversions

    func testToRAD() {
        sci.stack[0] = 180
        sci.dispatch("→RAD")
        XCTAssertEqual(sci.stack[0], Double.pi, accuracy: 1e-10)
    }

    func testToDEG() {
        sci.stack[0] = Double.pi
        sci.dispatch("→DEG")
        XCTAssertEqual(sci.stack[0], 180.0, accuracy: 1e-10)
    }

    // MARK: - Polar ↔ Rectangular

    func testToP_firstQuadrant() {
        sci.stack[1] = 3; sci.stack[0] = 4   // x=3, y=4 → r=5, θ=53.13°
        sci.dispatch("→P")
        XCTAssertEqual(sci.stack[1], 5.0, accuracy: 1e-10)          // r
        XCTAssertEqual(sci.stack[0], 53.13010235, accuracy: 1e-6)   // θ in degrees
    }

    func testToR_roundTrip() {
        sci.stack[1] = 3; sci.stack[0] = 4
        sci.dispatch("→P")
        sci.dispatch("→R")
        XCTAssertEqual(sci.stack[1], 3.0, accuracy: 1e-10)   // x
        XCTAssertEqual(sci.stack[0], 4.0, accuracy: 1e-10)   // y
    }

    // MARK: - Time conversions

    func testToHMS() {
        sci.stack[0] = 1.5    // 1.5 decimal hours = 1h 30m 0s → 1.3000
        sci.dispatch("→H.MS")
        XCTAssertEqual(sci.stack[0], 1.3, accuracy: 1e-6)
    }

    func testToH() {
        sci.stack[0] = 1.3    // 1h 30m → 1.5 decimal hours
        sci.dispatch("→H")
        XCTAssertEqual(sci.stack[0], 1.5, accuracy: 1e-6)
    }

    func testHMS_roundTrip() {
        let original = 2.4524   // 2h 45m 24s in H.MMSS format
        sci.stack[0] = original
        sci.dispatch("→H")
        sci.dispatch("→H.MS")
        XCTAssertEqual(sci.stack[0], original, accuracy: 1e-6)
    }

    // MARK: - Permutations and combinations

    func testPermutations() {
        sci.stack[1] = 5; sci.stack[0] = 3   // P(5,3) = 60
        sci.dispatch("Py,x")
        XCTAssertEqual(sci.stack[0], 60.0, accuracy: 0)
    }

    func testCombinations() {
        sci.stack[1] = 5; sci.stack[0] = 3   // C(5,3) = 10
        sci.dispatch("Cy,x")
        XCTAssertEqual(sci.stack[0], 10.0, accuracy: 0)
    }

    func testCombinations_C_n_0() {
        sci.stack[1] = 7; sci.stack[0] = 0   // C(7,0) = 1
        sci.dispatch("Cy,x")
        XCTAssertEqual(sci.stack[0], 1.0, accuracy: 0)
    }

    // MARK: - Linear regression

    func testLinearRegression_perfect() {
        // y = 2x + 1:  (1,3), (2,5), (3,7)
        sci.stack[1] = 3; sci.stack[0] = 1; sci.dispatch("Σ+")
        sci.stack[1] = 5; sci.stack[0] = 2; sci.dispatch("Σ+")
        sci.stack[1] = 7; sci.stack[0] = 3; sci.dispatch("Σ+")
        sci.dispatch("L.R.")
        XCTAssertEqual(sci.stack[0], 2.0, accuracy: 1e-10)   // slope
        XCTAssertEqual(sci.stack[1], 1.0, accuracy: 1e-10)   // intercept
    }

    func testYHat() {
        sci.stack[1] = 3; sci.stack[0] = 1; sci.dispatch("Σ+")
        sci.stack[1] = 5; sci.stack[0] = 2; sci.dispatch("Σ+")
        sci.stack[1] = 7; sci.stack[0] = 3; sci.dispatch("Σ+")
        sci.stack[0] = 4   // predict ŷ at x=4 → should be 9
        sci.dispatch("ŷ,r")
        XCTAssertEqual(sci.stack[0], 9.0, accuracy: 1e-10)
        XCTAssertEqual(sci.stack[1], 1.0, accuracy: 1e-10)   // perfect correlation r=1
    }
}

final class CasioEngineTests: XCTestCase {

    var eng: CasioEngine!

    override func setUp() { eng = CasioEngine() }

    // MARK: - Basic arithmetic

    func testAddition() {
        "2+3=".forEach { eng.dispatch(String($0)) }
        XCTAssertEqual(eng.displayText, "5")
    }

    func testSubtraction() {
        "10-7=".forEach { eng.dispatch(String($0)) }
        XCTAssertEqual(eng.displayText, "3")
    }

    func testMultiplication() {
        ["3", "×", "4", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(eng.displayText, "12")
    }

    func testDivision() {
        ["1", "0", "÷", "4", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(eng.displayText, "2.5")
    }

    func testChainedOps() {
        ["2", "+", "3", "+", "4", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(eng.displayText, "9")
    }

    // MARK: - Expression building & hasResult

    func testDigitAfterResultStartsFresh() {
        "5+5=".forEach { eng.dispatch(String($0)) }
        eng.dispatch("3")
        XCTAssertEqual(eng.expression, "3")
    }

    func testOperatorAfterResultContinues() {
        "4+4=".forEach { eng.dispatch(String($0)) }   // result = 8
        eng.dispatch("+")
        eng.dispatch("2")
        eng.dispatch("=")
        XCTAssertEqual(eng.displayText, "10")
    }

    // MARK: - AC / DEL

    func testAC_clearsAll() {
        "99+1=".forEach { eng.dispatch(String($0)) }
        eng.dispatch("AC")
        XCTAssertEqual(eng.displayText, "0")
        XCTAssertEqual(eng.expression, "")
    }

    func testDEL_removesLastChar() {
        ["1", "2", "3", "DEL"].forEach { eng.dispatch($0) }
        XCTAssertEqual(eng.expression, "12")
    }

    func testDEL_afterResult_clearsToZero() {
        "5+5=".forEach { eng.dispatch(String($0)) }
        eng.dispatch("DEL")
        XCTAssertEqual(eng.displayText, "0")
    }

    // MARK: - Sign / percent

    func testToggleSign() {
        eng.dispatch("5")
        eng.dispatch("±")
        XCTAssertEqual(eng.expression, "-5")
        eng.dispatch("±")
        XCTAssertEqual(eng.expression, "5")
    }

    func testPercent() {
        eng.dispatch("2")
        eng.dispatch("0")
        eng.dispatch("0")
        eng.dispatch("%")
        XCTAssertEqual(eng.displayText, "2")
    }

    // MARK: - Parentheses

    func testParentheses() {
        ["(", "2", "+", "3", ")", "×", "4", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(eng.displayText, "20")
    }

    // MARK: - Unary operations

    // Natural display: function wraps argument — type fn, arg, ), =

    func testSquareRoot() {
        ["√", "9", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(eng.displayText, "3")
    }

    func testSquareRoot_negativeIsError() {
        ["√", "-", "4", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(eng.displayText, "Math ERROR")
    }

    func testSquare() {
        eng.dispatch("3"); eng.dispatch("x²")
        XCTAssertEqual(eng.displayText, "9")
    }

    func testCube() {
        eng.dispatch("2"); eng.dispatch("x³")
        XCTAssertEqual(eng.displayText, "8")
    }

    func testCubeRoot() {
        ["³√", "8", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(Double(eng.displayText) ?? 0, 2.0, accuracy: 1e-10)
    }

    func testReciprocal() {
        eng.dispatch("4"); eng.dispatch("1/x")
        XCTAssertEqual(eng.displayText, "0.25")
    }

    func testReciprocal_zeroIsError() {
        eng.dispatch("0"); eng.dispatch("1/x")
        XCTAssertEqual(eng.displayText, "Math ERROR")
    }

    // MARK: - Trig (degrees)

    func testSin30() {
        ["sin", "3", "0", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(Double(eng.displayText) ?? 0, 0.5, accuracy: 1e-10)
    }

    func testCos60() {
        ["cos", "6", "0", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(Double(eng.displayText) ?? 0, 0.5, accuracy: 1e-10)
    }

    func testTan45() {
        ["tan", "4", "5", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(Double(eng.displayText) ?? 0, 1.0, accuracy: 1e-10)
    }

    func testTan90_isError() {
        ["tan", "9", "0", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(eng.displayText, "Math ERROR")
    }

    func testArcSin() {
        ["sin⁻¹", "0", ".", "5", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(Double(eng.displayText) ?? 0, 30.0, accuracy: 1e-8)
    }

    func testArcSin_domainError() {
        ["sin⁻¹", "2", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(eng.displayText, "Math ERROR")
    }

    func testArcCos() {
        ["cos⁻¹", "0", ".", "5", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(Double(eng.displayText) ?? 0, 60.0, accuracy: 1e-8)
    }

    func testArcTan() {
        ["tan⁻¹", "1", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(Double(eng.displayText) ?? 0, 45.0, accuracy: 1e-8)
    }

    // MARK: - Log / exp

    func testLog100() {
        ["log", "1", "0", "0", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(Double(eng.displayText) ?? 0, 2.0, accuracy: 1e-10)
    }

    func testLog_nonPositiveIsError() {
        ["log", "0", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(eng.displayText, "Math ERROR")
    }

    func testLn() {
        // ln(e) = 1 — uses the e constant token
        ["ln", "e", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(Double(eng.displayText) ?? 0, 1.0, accuracy: 1e-5)
    }

    func testPow10() {
        ["10^x", "2", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(Double(eng.displayText) ?? 0, 100.0, accuracy: 1e-10)
    }

    func testExpX() {
        ["e^x", "0", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(Double(eng.displayText) ?? 0, 1.0, accuracy: 1e-10)
    }

    // MARK: - π

    func testPi() {
        eng.dispatch("π")
        XCTAssertEqual(Double(eng.displayText) ?? 0, Double.pi, accuracy: 1e-10)
    }

    // MARK: - Tape

    func testTapeGrowsOnEquals() {
        "3+4=".forEach { eng.dispatch(String($0)) }
        XCTAssertEqual(eng.tape.count, 1)
        XCTAssertEqual(eng.tape[0].result, "7")
    }

    func testTapeGrowsOnUnary() {
        ["√", "9", ")", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(eng.tape.count, 1)
    }

    // MARK: - Decimal

    func testDecimalInput() {
        ["1", ".", "5", "+", "1", ".", "5", "="].forEach { eng.dispatch($0) }
        XCTAssertEqual(eng.displayText, "3")
    }

    func testDuplicateDecimalIgnored() {
        ["1", ".", ".", "5"].forEach { eng.dispatch($0) }
        XCTAssertEqual(eng.expression, "1..5".replacingOccurrences(of: "..", with: "."))
        // expression should be "1.5" (second dot ignored)
        XCTAssertFalse(eng.expression.filter { $0 == "." }.count > 1)
    }
}

final class HPFinancialEngineExtraTests: XCTestCase {

    var fin: HPFinancialEngine!

    override func setUp() { fin = HPFinancialEngine() }

    func testLSTx_afterArithmetic() {
        fin.stack[1] = 10; fin.stack[0] = 3
        fin.dispatch("+")       // lastX = 3
        fin.dispatch("LSTx")
        XCTAssertEqual(fin.stack[0], 3.0, accuracy: 1e-10)
    }

    func testLSTx_after1overX() {
        fin.stack[0] = 4
        fin.dispatch("1/x")    // lastX = 4
        fin.dispatch("LSTx")
        XCTAssertEqual(fin.stack[0], 4.0, accuracy: 1e-10)
    }

    func testSTO_RCL() {
        fin.stack[0] = 42
        fin.dispatch("STO"); fin.dispatch("3")
        fin.stack[0] = 0
        fin.dispatch("RCL"); fin.dispatch("3")
        XCTAssertEqual(fin.stack[0], 42.0, accuracy: 0)
    }

    func testCHS_togglesSign() {
        fin.stack[0] = 5
        fin.dispatch("CHS")
        XCTAssertEqual(fin.stack[0], -5.0, accuracy: 0)
        fin.dispatch("CHS")
        XCTAssertEqual(fin.stack[0], 5.0, accuracy: 0)
    }

    func testRollDown() {
        fin.stack = [1, 2, 3, 4]
        fin.dispatch("R↓")
        XCTAssertEqual(fin.stack[0], 2.0, accuracy: 0)
        XCTAssertEqual(fin.stack[1], 3.0, accuracy: 0)
        XCTAssertEqual(fin.stack[3], 1.0, accuracy: 0)
    }

    func testSwapXY() {
        fin.stack[0] = 7; fin.stack[1] = 13
        fin.dispatch("x≷y")
        XCTAssertEqual(fin.stack[0], 13.0, accuracy: 0)
        XCTAssertEqual(fin.stack[1], 7.0, accuracy: 0)
    }

    func testDivisionByZero() {
        fin.stack[0] = 0
        fin.dispatch("÷")
        XCTAssertEqual(fin.displayText, "Error")
    }

    func testPercentCalc() {
        fin.stack[1] = 500; fin.stack[0] = 20
        fin.dispatch("%")
        XCTAssertEqual(fin.stack[0], 100.0, accuracy: 1e-10)
    }

    func testDeltaPercent() {
        fin.stack[1] = 80; fin.stack[0] = 100
        fin.dispatch("Δ%")
        XCTAssertEqual(fin.stack[0], 25.0, accuracy: 1e-10)
    }
}
