-- Copyright 2018 Jonas Fuhrmann. All rights reserved.
--
-- This project is dual licensed under GNU General Public License version 3
-- and a commercial license available on request.
---------------------------------------------------------------------------
-- For non commercial use only:
-- This file is part of tinyTPU.
-- 
-- tinyTPU is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- tinyTPU is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with tinyTPU. If not, see <http://www.gnu.org/licenses/>.

--! @file ACTIVATION.vhdl
--! @author Jonas Fuhrmann
--! @brief This component calculates the selected activation function for the input array.
--! @details The input is rounded, has some checker logic for ReLU and look-up-tables for the sigmoid function.
--! All functions are quantized.

use WORK.TPU_pack.all;
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    
entity ACTIVATION is
    generic(
        MATRIX_WIDTH        : natural := 14;
        BIAS_ARRAY_SIZE     : natural := 1778
    );
    port(
        CLK, RESET          : in  std_logic;
        ENABLE              : in  std_logic;
        
        ACTIVATION_FUNCTION : in  ACTIVATION_BIT_TYPE;
        SIGNED_NOT_UNSIGNED : in  std_logic;
        
        ACTIVATION_INPUT    : in  WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
        ACTIVATION_OUTPUT   : out BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1)
    );
end entity ACTIVATION;

--! @brief The architecture of the activation component.
architecture BEH of ACTIVATION is
    
    type BIAS_ARRAY_TYPE is array(0 to BIAS_ARRAY_SIZE-1) of integer range -2147483648 to 2147483647;
    constant BIAS_ARRAY : BIAS_ARRAY_TYPE := (
    12303,-9129,-90953,-38433,1844,-46339,-8429,98407,-14237,2034,4173,-3357,-47340,662,
    483,14642,37424,20611,9372,-15385,-140227,-2994,36648,18936,34842,92120,-45295,31911,
    -7496,-18087,-13662,-7471,-13712,-41714,15735,-9419,29426,21613,-11415,-32303,32541,1720,
    -7297,4980,-994,-214,-33829,8808,85101,-22046,-23326,-12995,-20682,-25917,-26287,-63787,
    -15727,-10086,-36022,-7071,791,18319,-23253,-61758,-68977,14261,-4488,8523,-19713,-12708,
    -4822,33444,28250,44567,45587,24709,-10860,-2895,-71149,21710,-2568,9890,-16511,7578,
    37746,39104,40642,4059,2739,19653,63828,-1852,69872,-96419,39778,6108,-9326,-24102,
    -56031,18948,19999,91314,20733,16738,18849,30281,-113625,12932,50240,-28012,2440,-19588,
    4822,-10091,-4369,-10820,-33133,-2162,27696,28855,-3419,-1949,25893,-37,5515,45905,
    -49242,57339,0,0,0,0,0,0,0,0,0,0,0,0,
    2355,-8,-25,-149,-916,-2779,515,-40,20,136,-117,-194,392,-130,
    239,302,286,138,460,231,432,402,-214,-60,790,-920,-3,-286,
    1158,-604,211,-41,63,-1266,258,429,203,-190,-335,136,-260,100,
    148,-17,-1636,217,748,-1448,-109,-135,-344,-202,-305,1744,153,-1878,
    37,824,115,-183,-186,-673,835,-110,550,489,412,-140,243,-296,
    194,277,-148,-160,1369,277,543,90,-259,-1666,63,-192,429,-286,
    -3128,-321,-544,142,476,-371,-416,-718,-499,-142,194,-239,500,-420,
    -767,126,25,-118,32,-123,-230,140,31,-1644,156,-38,1836,119,
    627,-321,-98,5,1050,464,628,-281,445,302,425,22,301,-34,
    555,-1818,0,0,0,0,0,0,0,0,0,0,0,0,
    525,268,-89,602,-190,71,165,-163,76,4,-21,-126,-19,-121,
    260,19,148,340,46,112,-1043,34,110,-27,227,-16,-82,29,
    -1125,37,137,-58,130,90,-94,171,-281,37,60,-21,562,69,
    -456,19,-73,69,-90,274,76,193,177,16,90,250,72,-22,
    -280,-288,-66,-1,-564,30,-100,-70,-63,62,92,120,167,-243,
    65,285,-137,-11,-42,30,64,265,-78,130,19,-57,-139,78,
    88,46,5,56,-19,289,278,84,-139,-18,-84,63,-117,-82,
    177,-190,-49,91,0,-40,143,35,-21,93,-7,28,69,-67,
    301,31,-101,202,87,150,-27,-15,-31,78,85,-163,194,14,
    588,4,0,0,0,0,0,0,0,0,0,0,0,0,
    264,-47,-990,110,-32,389,-170,-3807,25,-2629,-2226,141,65,-12,
    242,193,-54,-641,35,-3844,-343,122,-109,61,157,-294,165,293,
    68,255,-118,-146,-2241,-321,29,-163,239,-23,-14,126,1615,808,
    180,389,29,-122,-38,-11,-19,-211,-249,124,330,-652,78,-509,
    -112,-670,75,520,-1161,-428,-92,-2,-335,623,317,-343,218,234,
    318,331,-76,52,46,200,486,-420,-346,34,551,110,74,334,
    -218,40,307,194,70,274,-505,22,-91,-199,-1811,92,442,-3504,
    433,-218,-80,399,-287,24,-389,-17,435,232,40,155,267,-327,
    -223,-995,-444,1489,-305,427,-117,102,-81,-2231,196,-3040,9,114,
    -365,-156,0,0,0,0,0,0,0,0,0,0,0,0,
    10945,12630,12251,12268,9983,11335,13857,10233,0,0,0,0,0,0,
    3964,1804,-8901,-1655,6137,-2630,8567,815,5410,-177,-7027,-3241,-4136,-392,
    2219,-1906,3430,661,3154,617,-3011,1584,-4651,6292,4702,637,-12498,1353,
    6197,-205,3615,13284,6589,-3187,1535,5959,7362,-7445,4144,-1884,3507,-3169,
    2440,728,-491,4017,3876,-633,-4564,3778,-3256,-2752,-1414,453,2392,-8880,
    -9491,-2742,-930,2009,-4588,-7157,-2062,2503,7156,5105,-1025,-3349,3776,-2651,
    9499,-7317,-3712,-4706,7017,-4730,6754,-8509,-8895,1163,-3049,678,5725,5214,
    6102,8807,-653,-3728,-3643,-1869,-956,707,-4361,10412,1237,4266,9191,-840,
    1,2323,5638,-6828,-5109,-7692,1832,1734,4181,411,1327,-5621,847,7109,
    -5045,1178,-2315,-639,4302,4757,7634,1158,-366,5297,-869,-1261,-7119,-5484,
    4262,7990,0,0,0,0,0,0,0,0,0,0,0,0,
    -900,-75,1466,-2044,208,825,865,648,1003,819,808,-379,-952,1212,
    707,861,925,-786,-1344,698,11,1186,347,984,-452,101,-312,600,
    177,-1758,-170,1389,-1209,-1975,994,69,2125,1487,865,298,-354,1440,
    834,762,3807,-332,1275,-2131,-473,2154,326,851,1483,-97,-302,-1116,
    138,1698,-868,-58,2667,1838,-1080,672,-260,-346,1153,-142,416,2392,
    -1538,-511,-1413,-348,1749,416,2058,-171,245,-1552,338,1085,58,414,
    688,-32,-1027,-1186,164,959,355,282,-2303,-581,2323,203,315,-739,
    1287,1193,-689,603,-231,-1584,2006,-3131,-201,-1271,-1382,-236,-610,858,
    1757,1123,-954,400,1657,-1112,95,1554,-657,-404,2455,660,1459,931,
    771,1966,0,0,0,0,0,0,0,0,0,0,0,0,
    162,1378,-886,315,-628,112,-595,916,513,-1478,1686,2779,5013,602,
    466,3556,78,-69,147,-558,654,1798,-1037,1732,96,941,2137,-977,
    -2470,1117,-88,738,549,-2857,-2372,-133,-1056,1464,319,-496,3099,381,
    3541,274,538,-727,1048,877,1870,2294,-1151,446,1278,-1304,1064,1243,
    -2294,-2567,1101,1522,59,1473,2692,2598,-479,2584,-479,-1705,1236,-405,
    -958,-2661,-1823,1576,-916,-2313,984,1285,-1438,-111,3283,1426,6053,-3021,
    3180,2107,-202,-1268,-1788,389,222,-12,-5142,-359,300,58,-591,290,
    -72,909,1348,-447,3013,3134,-568,704,617,1719,-264,2013,893,2571,
    1751,705,-155,538,-1961,2560,3,-373,-773,5592,-356,919,3879,726,
    -4399,-1456,0,0,0,0,0,0,0,0,0,0,0,0,
    -122,10381,13187,14358,2225,8536,2072,3757,4428,8268,714,3892,6579,11927,
    7075,5203,16263,5477,3201,8543,13686,9948,6546,-639,2128,5008,-2073,2236,
    9114,10742,6664,7622,8477,2337,4073,2529,5319,9023,3426,3715,3752,1666,
    3946,9948,2448,5407,1298,2130,11032,3775,4399,-2986,3816,8102,5279,6764,
    2720,6052,8143,8240,5743,10706,11431,7128,4685,-2312,98,9617,1706,5551,
    4621,195,10556,4203,8268,5028,5837,5562,-2542,6876,3791,13779,4081,3720,
    10230,3751,8423,4315,1691,8649,1297,10974,2604,10257,11353,2028,5516,4567,
    9989,5725,11312,9996,5658,3804,3726,6707,9074,5276,13163,5704,3027,7901,
    -618,1661,2063,4140,5627,3328,3180,-2145,7451,4927,3540,3468,4061,3903,
    6545,8147,0,0,0,0,0,0,0,0,0,0,0,0,
    -2686,-1187,-684,26,-18,313,-443,-83,0,85,-255,-408,-337,-42,
    -595,-495,-606,-264,-411,-603,-699,-682,-587,-648,-906,-879,-1330,-715,
    -703,-801,-722,-550,-693,-769,-863,-633,-657,-794,-985,-701,-1023,-768,
    -866,-1041,-1152,-752,-686,-877,-1057,-1022,-845,-688,-726,-766,-790,-995,
    -897,-1029,-1044,-1099,-1213,-955,-1076,-1199,-1039,-1022,-1180,-1516,-1395,-1235,
    -1278,-1116,-1162,-1178,-1118,-1254,-1161,-1175,-1185,-1252,-1199,-1296,-1439,-1707,
    -1674,-1986,-1734,-1671,-1572,-1759,-1276,-1566,-1600,-1752,-1478,-1397,-1735,-1785,
    -1777,-1616,-1521,-1613,-1907,-1780,-1959,-1968,-1801,-2186,-2474,-2238,-1801,-2037,
    -2159,-2332,-1947,-1949,-1954,-1997,-2398,-2249,-2147,-1855,-2059,-1651,-1479,-1669,
    -2589,-4426,-2524,-1077,-655,9,-100,268,-424,-205,-117,10,-317,-474,
    -381,-86,-673,-592,-728,-392,-447,-536,-682,-711,-636,-698,-930,-897,
    -1312,-681,-738,-831,-680,-568,-632,-766,-955,-741,-728,-790,-979,-646,
    -955,-763,-884,-1010,-1044,-692,-716,-925,-1036,-1036,-953,-820,-816,-838,
    -779,-926,-940,-1063,-1071,-1199,-1323,-1029,-1147,-1215,-1057,-1032,-1216,-1577,
    -1384,-1298,-1391,-1147,-1221,-1225,-1174,-1210,-1126,-1239,-1272,-1270,-1177,-1211,
    -1344,-1636,-1575,-1916,-1647,-1484,-1492,-1702,-1258,-1466,-1539,-1662,-1397,-1332,
    -1635,-1664,-1637,-1507,-1475,-1499,-1815,-1725,-1876,-1883,-1570,-1889,-2187,-1982,
    -1468,-1710,-1927,-2062,-1699,-1754,-1785,-1881,-2282,-2184,-2004,-1718,-1940,-1521,
    -1369,-1504,-2460,-4220,-2420,-1006,-617,42,-142,314,-347,-306,-215,4,
    -266,-482,-450,-148,-764,-623,-808,-431,-377,-407,-667,-702,-630,-579,
    -885,-930,-1231,-581,-710,-774,-639,-553,-643,-743,-969,-677,-649,-731,
    -952,-567,-930,-773,-841,-944,-1012,-710,-725,-966,-997,-985,-992,-860,
    -815,-807,-765,-924,-953,-1049,-1081,-1181,-1358,-1055,-1141,-1237,-1039,-1038,
    -1257,-1510,-1390,-1302,-1380,-1128,-1214,-1189,-1169,-1187,-1138,-1138,-1176,-1197,
    -1182,-1165,-1302,-1586,-1582,-1996,-1701,-1462,-1444,-1617,-1273,-1465,-1567,-1763,
    -1461,-1339,-1702,-1685,-1673,-1593,-1582,-1488,-1893,-1831,-1964,-1959,-1650,-1946,
    -2282,-2068,-1437,-1706,-1956,-2048,-1674,-1753,-1855,-1982,-2394,-2280,-2043,-1820,
    -2013,-1585,-1425,-1584,-2535,-4247,-2455,-1019,-591,34,-81,338,-322,-410,
    -384,-106,-373,-504,-402,-110,-753,-648,-824,-440,-313,-416,-707,-679,
    -540,-482,-755,-909,-1216,-542,-618,-743,-579,-455,-673,-745,-953,-634,
    -619,-710,-922,-637,-928,-728,-744,-884,-1004,-695,-716,-943,-998,-1056,
    -962,-850,-798,-855,-757,-930,-930,-990,-1071,-1241,-1303,-1016,-1097,-1273,
    -1075,-1086,-1267,-1433,-1384,-1257,-1291,-1103,-1173,-1082,-1073,-1161,-1099,-1080,
    -1112,-1111,-1294,-1204,-1327,-1591,-1569,-2052,-1721,-1518,-1460,-1538,-1291,-1494,
    -1558,-1775,-1456,-1344,-1736,-1685,-1697,-1598,-1600,-1453,-1893,-1863,-1992,-1958,
    -1673,-2032,-2380,-2245,-1510,-1765,-2020,-2119,-1677,-1745,-1845,-1969,-2494,-2296,
    -2002,-1797,-1992,-1389,-1249,-1513,-2444,-4139,-2584,-1172,-702,45,36,390,
    -249,-347,-408,-125,-325,-475,-335,-36,-697,-616,-767,-423,-345,-442,
    -750,-697,-492,-414,-670,-862,-1227,-662,-598,-698,-573,-523,-798,-795,
    -970,-697,-644,-697,-909,-674,-973,-706,-727,-827,-1029,-668,-704,-959,
    -992,-1081,-898,-784,-834,-927,-762,-933,-901,-883,-987,-1224,-1361,-1060,
    -1137,-1250,-1096,-1158,-1184,-1369,-1341,-1285,-1315,-1035,-1108,-1051,-1070,-1171,
    -1114,-1052,-1101,-1141,-1424,-1317,-1412,-1659,-1592,-2109,-1737,-1454,-1423,-1587,
    -1385,-1520,-1618,-1782,-1477,-1488,-1836,-1715,-1734,-1628,-1613,-1475,-1893,-1912,
    -1987,-2022,-1760,-2119,-2574,-2387,-1720,-1962,-2175,-2296,-1813,-1870,-2014,-2107,
    -2612,-2481,-2107,-1883,-2116,-1423,-1308,-1641,-2618,-4350,0,0,0,0
    );
    
    signal bias_index : integer range 0 to BIAS_ARRAY_SIZE-1 := 0; -- ????
    signal adjusted_input : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
    constant MAX_BIAS_INDEX : integer := BIAS_ARRAY_SIZE / MATRIX_WIDTH - 1;
    
    constant SIGMOID_UNSIGNED   : INTEGER_ARRAY_TYPE(0 to 164)  := (128,130,132,134,136,138,140,142,144,146,148,150,152,154,156,157,159,161,163,165,167,169,170,172,174,176,177,179,181,182,184,186,187,189,190,192,193,195,196,198,199,200,202,203,204,206,207,208,209,210,212,213,214,215,216,217,218,219,220,221,222,223,224,225,225,226,227,228,229,229,230,231,232,232,233,234,234,235,235,236,237,237,238,238,239,239,240,240,241,241,241,242,242,243,243,243,244,244,245,245,245,246,246,246,246,247,247,247,248,248,248,248,248,249,249,249,249,250,250,250,250,250,250,251,251,251,251,251,251,252,252,252,252,252,252,252,252,253,253,253,253,253,253,253,253,253,253,253,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,254);
    constant SIGMOID_SIGNED     : INTEGER_ARRAY_TYPE(-88 to 70) := (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,3,3,3,3,3,4,4,4,4,4,5,5,5,6,6,6,7,7,8,8,9,9,10,10,11,12,12,13,14,14,15,16,17,18,19,20,21,22,23,25,26,27,29,30,31,33,34,36,38,39,41,43,45,46,48,50,52,54,56,58,60,62,64,66,68,70,72,74,76,78,80,82,83,85,87,89,90,92,94,95,97,98,99,101,102,103,105,106,107,108,109,110,111,112,113,114,114,115,116,116,117,118,118,119,119,120,120,121,121,122,122,122,123,123,123,124,124,124,124,124,125,125,125,125,125,126,126,126,126,126,126,126,126);

    type SIGMOID_ARRAY_TYPE is array(natural range<>) of std_logic_vector(20 downto 0);
    type RELU_ARRAY_TYPE is array(natural range<>) of std_logic_vector(3*BYTE_WIDTH-1 downto 0);
    
    signal INPUT_REG_cs     : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1) := (others => (others => '0'));
    signal INPUT_REG_ns     : WORD_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
    
    signal INPUT_PIPE0_cs   : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1) := (others => (others => '0'));
    signal INPUT_PIPE0_ns   : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
    
    signal RELU_ROUND_REG_cs    : RELU_ARRAY_TYPE(0 to MATRIX_WIDTH-1) := (others => (others => '0'));
    signal RELU_ROUND_REG_ns    : RELU_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
    
    signal SIGMOID_ROUND_REG_cs : SIGMOID_ARRAY_TYPE(0 to MATRIX_WIDTH-1) := (others => (others => '0'));
    signal SIGMOID_ROUND_REG_ns : SIGMOID_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
    
    signal RELU_OUTPUT      : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
    signal SIGMOID_OUTPUT   : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
    
    signal OUTPUT_REG_cs    : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1) := (others => (others => '0'));
    signal OUTPUT_REG_ns    : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
    
    signal ACTIVATION_FUNCTION_REG0_cs  : ACTIVATION_BIT_TYPE := (others => '0');
    signal ACTIVATION_FUNCTION_REG0_ns  : ACTIVATION_BIT_TYPE;
    signal ACTIVATION_FUNCTION_REG1_cs  : ACTIVATION_BIT_TYPE := (others => '0');
    signal ACTIVATION_FUNCTION_REG1_ns  : ACTIVATION_BIT_TYPE;
    
    signal SIGNED_NOT_UNSIGNED_REG_cs   : std_logic_vector(0 to 1) := (others => '0');
    signal SIGNED_NOT_UNSIGNED_REG_ns   : std_logic_vector(0 to 1);
    signal enable_last    : std_logic := '0';
begin

--    INPUT_REG_ns    <= ACTIVATION_INPUT;
    INPUT_REG_ns    <= adjusted_input;    
    UPDATE_BIAS_INDEX: process(CLK)
        variable next_bias_index : integer;
    begin
        if CLK'event and CLK = '1' then
            if RESET = '1' then
                bias_index <= 0; -- ???????
                enable_last <= '0';
            else
                if ENABLE = '1' and enable_last = '0' then -- ?? ENABLE ????
                    next_bias_index := bias_index + 14;
                    if next_bias_index > (BIAS_ARRAY_SIZE / MATRIX_WIDTH - 1) then
                        next_bias_index := 0; -- ??????
                    end if;
                    bias_index <= next_bias_index;
                end if;
                enable_last <= ENABLE; -- ???? ENABLE ?????????
            end if;
        end if;
    end process UPDATE_BIAS_INDEX;
    
    ADD_BIAS: process(bias_index, ACTIVATION_INPUT)
            variable current_bias : integer;
    begin
        for i in 0 to MATRIX_WIDTH-1 loop
--            current_bias := BIAS_ARRAY(bias_index);
            adjusted_input(i) <= std_logic_vector(signed(ACTIVATION_INPUT(i)) + to_signed(BIAS_ARRAY(bias_index + i), ACTIVATION_INPUT(i)'length));
--            adjusted_input(i) <= std_logic_vector(signed(ACTIVATION_INPUT(i)));
        end loop;
    end process ADD_BIAS;
    
    ROUND:
    process(INPUT_REG_cs, SIGNED_NOT_UNSIGNED_REG_cs(0)) is
    begin
        for i in 0 to MATRIX_WIDTH-1 loop
            INPUT_PIPE0_ns(i)       <= INPUT_REG_cs(i)(4*BYTE_WIDTH-1 downto 3*BYTE_WIDTH);
            RELU_ROUND_REG_ns(i)    <= std_logic_vector(unsigned(INPUT_REG_cs(i)(4*BYTE_WIDTH-1 downto 1*BYTE_WIDTH)) + INPUT_REG_cs(i)(1*BYTE_WIDTH-1));
            
            if SIGNED_NOT_UNSIGNED_REG_cs(0) = '0' then
                -- unsigned - Qu3.5 table range
                SIGMOID_ROUND_REG_ns(i) <= std_logic_vector(unsigned(INPUT_REG_cs(i)(4*BYTE_WIDTH-1 downto 2*BYTE_WIDTH-5)) + INPUT_REG_cs(i)(2*BYTE_WIDTH-6));
            else
                -- signed - Q4.4 table range
                SIGMOID_ROUND_REG_ns(i) <= std_logic_vector(unsigned(INPUT_REG_cs(i)(4*BYTE_WIDTH-1 downto 2*BYTE_WIDTH-4)) + INPUT_REG_cs(i)(2*BYTE_WIDTH-5)) & '0';
            end if;
        end loop;
    end process ROUND;
    
    ACTIVATION_FUNCTION_REG0_ns <= ACTIVATION_FUNCTION;
    ACTIVATION_FUNCTION_REG1_ns <= ACTIVATION_FUNCTION_REG0_cs;
    
    SIGNED_NOT_UNSIGNED_REG_ns(0) <= SIGNED_NOT_UNSIGNED;
    SIGNED_NOT_UNSIGNED_REG_ns(1) <= SIGNED_NOT_UNSIGNED_REG_cs(0);
    
    RELU_ACTIVATION:
    process(SIGNED_NOT_UNSIGNED_REG_cs(1), RELU_ROUND_REG_cs) is
        variable SIGNED_NOT_UNSIGNED_v  : std_logic;
        variable RELU_ROUND_v           : RELU_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
        
        variable RELU_OUTPUT_v          : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
    begin
        SIGNED_NOT_UNSIGNED_v   := SIGNED_NOT_UNSIGNED_REG_cs(1);
        RELU_ROUND_v            := RELU_ROUND_REG_cs;
        
        for i in 0 to MATRIX_WIDTH-1 loop
            if SIGNED_NOT_UNSIGNED_v = '1' then
                if    signed(RELU_ROUND_v(i)) <   0 then
                    RELU_OUTPUT_v(i) := (others => '0');
                elsif signed(RELU_ROUND_v(i)) > 127 then -- Bounded ReLU
                    RELU_OUTPUT_v(i) := std_logic_vector(to_signed(127, BYTE_WIDTH));
                else
                    RELU_OUTPUT_v(i) := RELU_ROUND_v(i)(BYTE_WIDTH-1 downto 0);
                end if;
            else
                if  unsigned(RELU_ROUND_v(i)) > 255 then -- Bounded ReLU
                    RELU_OUTPUT_v(i) := std_logic_vector(to_unsigned(255, BYTE_WIDTH));
                else
                    RELU_OUTPUT_v(i) := RELU_ROUND_v(i)(BYTE_WIDTH-1 downto 0);
                end if;
            end if;
        end loop;
        
        RELU_OUTPUT <= RELU_OUTPUT_v;
    end process RELU_ACTIVATION;
    
    SIGMOID_ACTIVATION:
    process(SIGNED_NOT_UNSIGNED_REG_cs(1), SIGMOID_ROUND_REG_cs) is
        variable SIGNED_NOT_UNSIGNED_v  : std_logic;
        variable SIGMOID_ROUND_v        : SIGMOID_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
        
        variable SIGMOID_OUTPUT_v       : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
    begin
        SIGNED_NOT_UNSIGNED_v   := SIGNED_NOT_UNSIGNED_REG_cs(1);
        SIGMOID_ROUND_v         := SIGMOID_ROUND_REG_cs;
        
        for i in 0 to MATRIX_WIDTH-1 loop
            if SIGNED_NOT_UNSIGNED_v = '1' then -- Signed
                if signed(SIGMOID_ROUND_v(i)(20 downto 1)) < -88 then
                    SIGMOID_OUTPUT_v(i) := (others => '0');
                elsif signed(SIGMOID_ROUND_v(i)(20 downto 1)) > 70 then
                    SIGMOID_OUTPUT_v(i) := std_logic_vector(to_signed(127, BYTE_WIDTH));
                else
                    SIGMOID_OUTPUT_v(i) := std_logic_vector(to_signed(to_integer(signed(SIGMOID_ROUND_v(i)(20 downto 1))), BYTE_WIDTH));
                end if;
            else    -- Unsigned
                if unsigned(SIGMOID_ROUND_v(i)) > 164 then
                    SIGMOID_OUTPUT_v(i) := std_logic_vector(to_unsigned(255, BYTE_WIDTH));
                else
                    SIGMOID_OUTPUT_v(i) := std_logic_vector(to_unsigned(to_integer(unsigned(SIGMOID_ROUND_v(i))), BYTE_WIDTH));
                end if;
            end if;
        end loop;
        
        SIGMOID_OUTPUT <= SIGMOID_OUTPUT_v;
    end process SIGMOID_ACTIVATION;
    
    CHOOSE_ACTIVATION:
    process(ACTIVATION_FUNCTION_REG1_cs, RELU_OUTPUT, SIGMOID_OUTPUT, INPUT_PIPE0_cs) is
        variable ACTIVATION_FUNCTION_v  : ACTIVATION_BIT_TYPE;
        variable RELU_OUTPUT_v          : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
        variable SIGMOID_OUTPUT_v       : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
        variable ACTIVATION_INPUT_v     : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
        
        variable OUTPUT_REG_ns_v        : BYTE_ARRAY_TYPE(0 to MATRIX_WIDTH-1);
    begin
        ACTIVATION_FUNCTION_v   := ACTIVATION_FUNCTION_REG1_cs;
        RELU_OUTPUT_v           := RELU_OUTPUT;
        SIGMOID_OUTPUT_v        := SIGMOID_OUTPUT;
        ACTIVATION_INPUT_v      := INPUT_PIPE0_cs;
        for i in 0 to MATRIX_WIDTH-1 loop            
            case BITS_TO_ACTIVATION(ACTIVATION_FUNCTION_v) is
                when RELU => OUTPUT_REG_ns_v(i) := RELU_OUTPUT_v(i);
                when SIGMOID => OUTPUT_REG_ns_v(i) := SIGMOID_OUTPUT_v(i);
                when NO_ACTIVATION => OUTPUT_REG_ns_v(i) := ACTIVATION_INPUT_v(i);
                when others => 
                    report "Unknown activation function!" severity ERROR;
                    OUTPUT_REG_ns_v(i) := ACTIVATION_INPUT_v(i);
            end case;
        end loop;
        
        OUTPUT_REG_ns <= OUTPUT_REG_ns_v;
    end process CHOOSE_ACTIVATION;
    
    ACTIVATION_OUTPUT <= OUTPUT_REG_cs;
    
    SEQ_LOG:
    process(CLK) is
    begin
        if CLK'event and CLK = '1' then
            if RESET = '1' then
                OUTPUT_REG_cs   <= (others => (others => '0'));
                INPUT_REG_cs    <= (others => (others => '0'));
                INPUT_PIPE0_cs  <= (others => (others => '0'));
                RELU_ROUND_REG_cs   <= (others => (others => '0'));
                SIGMOID_ROUND_REG_cs<= (others => (others => '0'));
                SIGNED_NOT_UNSIGNED_REG_cs  <= (others => '0');
                ACTIVATION_FUNCTION_REG0_cs <= (others => '0');
                ACTIVATION_FUNCTION_REG1_cs <= (others => '0');
            else
                if ENABLE = '1' then
                    OUTPUT_REG_cs   <= OUTPUT_REG_ns;
                    INPUT_REG_cs    <= INPUT_REG_ns;
                    INPUT_PIPE0_cs  <= INPUT_PIPE0_ns;
                    RELU_ROUND_REG_cs   <= RELU_ROUND_REG_ns;
                    SIGMOID_ROUND_REG_cs<= SIGMOID_ROUND_REG_ns;
                    SIGNED_NOT_UNSIGNED_REG_cs  <= SIGNED_NOT_UNSIGNED_REG_ns;
                    ACTIVATION_FUNCTION_REG0_cs <= ACTIVATION_FUNCTION_REG0_ns;
                    ACTIVATION_FUNCTION_REG1_cs <= ACTIVATION_FUNCTION_REG1_ns;
                end if;
            end if;
        end if;
    end process SEQ_LOG;
    
end architecture BEH;