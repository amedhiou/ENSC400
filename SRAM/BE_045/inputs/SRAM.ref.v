
module SRAM ( clk, rdn, wrn, address, bit_wen, data_in, data_out );
  input [10:0] address;
  input [31:0] bit_wen;
  input [31:0] data_in;
  output [31:0] data_out;
  input clk, rdn, wrn;
  wire   N3, N5, N6, N7, N8, N9, N10, N11, N12, N13, N14, N15, N16, N17, N18,
         N19, N20, N21, N22, N23, N24, N25, N26, N27, N28, N29, N30, N31, N32,
         N33, N34, N35, N36, N37, N38, N39, N40, N41, N42, N43, N44, N45, N46,
         N47, N48, N49, N50, N51, N52, N53, N54, N55, N56, N57, N58, N59, N60,
         N61, N62, N63, N64, N65, N66, N67, N68, N69, N70, N71, N72, N73, N74,
         N75, N76, N77, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13,
         n14, n15, n16, n17, n18, n19, n20, n21, n22, n23, n24, n25, n26, n27,
         n28, n29, n30, n31, n32, n33, n34, n35, n36, n37, n38, n39, n40, n41,
         n42, n43, n44, n45, n46, n47, n48, n49, n50, n51, n52, n53, n54, n55,
         n56, n57, n58, n59, n60, n61, n62, n63, n64, n65, n66, n67, n68, n69,
         n70, n71, n72, n73, n74, n75, n76, n77, n78, n79, n80, n81, n82, n83,
         n84, n85, n86, n87, n88, n89, n90, n91, n92, n93, n94, n95, n96, n97,
         n98, n99, n100, n101, n102, n103, n104, n105, n106, n107, n108, n109,
         n110, n111, n112, n113, n114, n115, n116, n117, n118, n119, n120,
         n121, n122, n123, n124, n125, n126, n127, n128, n129, n130, n131,
         n132, n165, n166, n167, n168, n169, n170, n171, n172, n173, n174,
         n175, n176, n177, n178, n179, n180, n181, n182, n183, n184, n185,
         n186, n187, n188, n189, n190, n191, n192, n193, n194, n195, n196,
         n197, n198, n199;
  wire   [31:0] M_reg;
  wire   [10:0] addr_reg;
  wire   [31:0] data_reg;

  XOR2_X1 C278 ( .A(data_reg[0]), .B(M_reg[0]), .Z(N68) );
  XOR2_X1 C277 ( .A(data_reg[1]), .B(M_reg[1]), .Z(N67) );
  XOR2_X1 C276 ( .A(data_reg[2]), .B(M_reg[2]), .Z(N66) );
  XOR2_X1 C275 ( .A(data_reg[3]), .B(M_reg[3]), .Z(N65) );
  XOR2_X1 C274 ( .A(data_reg[4]), .B(M_reg[4]), .Z(N64) );
  XOR2_X1 C273 ( .A(data_reg[5]), .B(M_reg[5]), .Z(N63) );
  XOR2_X1 C272 ( .A(data_reg[6]), .B(M_reg[6]), .Z(N62) );
  XOR2_X1 C271 ( .A(data_reg[7]), .B(M_reg[7]), .Z(N61) );
  XOR2_X1 C270 ( .A(data_reg[8]), .B(M_reg[8]), .Z(N60) );
  XOR2_X1 C269 ( .A(data_reg[9]), .B(M_reg[9]), .Z(N59) );
  XOR2_X1 C268 ( .A(data_reg[10]), .B(M_reg[10]), .Z(N58) );
  XOR2_X1 C267 ( .A(data_reg[11]), .B(M_reg[11]), .Z(N57) );
  XOR2_X1 C266 ( .A(data_reg[12]), .B(M_reg[12]), .Z(N56) );
  XOR2_X1 C265 ( .A(data_reg[13]), .B(M_reg[13]), .Z(N55) );
  XOR2_X1 C264 ( .A(data_reg[14]), .B(M_reg[14]), .Z(N54) );
  XOR2_X1 C263 ( .A(data_reg[15]), .B(M_reg[15]), .Z(N53) );
  XOR2_X1 C262 ( .A(data_reg[16]), .B(M_reg[16]), .Z(N52) );
  XOR2_X1 C261 ( .A(data_reg[17]), .B(M_reg[17]), .Z(N51) );
  XOR2_X1 C260 ( .A(data_reg[18]), .B(M_reg[18]), .Z(N50) );
  XOR2_X1 C259 ( .A(data_reg[19]), .B(M_reg[19]), .Z(N49) );
  XOR2_X1 C258 ( .A(data_reg[20]), .B(M_reg[20]), .Z(N48) );
  XOR2_X1 C257 ( .A(data_reg[21]), .B(M_reg[21]), .Z(N47) );
  XOR2_X1 C256 ( .A(data_reg[22]), .B(M_reg[22]), .Z(N46) );
  XOR2_X1 C255 ( .A(data_reg[23]), .B(M_reg[23]), .Z(N45) );
  XOR2_X1 C254 ( .A(data_reg[24]), .B(M_reg[24]), .Z(N44) );
  XOR2_X1 C253 ( .A(data_reg[25]), .B(M_reg[25]), .Z(N43) );
  XOR2_X1 C252 ( .A(data_reg[26]), .B(M_reg[26]), .Z(N42) );
  XOR2_X1 C251 ( .A(data_reg[27]), .B(M_reg[27]), .Z(N41) );
  XOR2_X1 C250 ( .A(data_reg[28]), .B(M_reg[28]), .Z(N40) );
  XOR2_X1 C249 ( .A(data_reg[29]), .B(M_reg[29]), .Z(N39) );
  XOR2_X1 C248 ( .A(data_reg[30]), .B(M_reg[30]), .Z(N38) );
  XOR2_X1 C247 ( .A(data_reg[31]), .B(M_reg[31]), .Z(N37) );
  AND2_X2 C246 ( .A1(data_reg[0]), .A2(M_reg[0]), .ZN(N36) );
  AND2_X2 C245 ( .A1(data_reg[1]), .A2(M_reg[1]), .ZN(N35) );
  AND2_X2 C244 ( .A1(data_reg[2]), .A2(M_reg[2]), .ZN(N34) );
  AND2_X2 C243 ( .A1(data_reg[3]), .A2(M_reg[3]), .ZN(N33) );
  AND2_X2 C242 ( .A1(data_reg[4]), .A2(M_reg[4]), .ZN(N32) );
  AND2_X2 C241 ( .A1(data_reg[5]), .A2(M_reg[5]), .ZN(N31) );
  AND2_X2 C240 ( .A1(data_reg[6]), .A2(M_reg[6]), .ZN(N30) );
  AND2_X2 C239 ( .A1(data_reg[7]), .A2(M_reg[7]), .ZN(N29) );
  AND2_X2 C238 ( .A1(data_reg[8]), .A2(M_reg[8]), .ZN(N28) );
  AND2_X2 C237 ( .A1(data_reg[9]), .A2(M_reg[9]), .ZN(N27) );
  AND2_X2 C236 ( .A1(data_reg[10]), .A2(M_reg[10]), .ZN(N26) );
  AND2_X2 C235 ( .A1(data_reg[11]), .A2(M_reg[11]), .ZN(N25) );
  AND2_X2 C234 ( .A1(data_reg[12]), .A2(M_reg[12]), .ZN(N24) );
  AND2_X2 C233 ( .A1(data_reg[13]), .A2(M_reg[13]), .ZN(N23) );
  AND2_X2 C232 ( .A1(data_reg[14]), .A2(M_reg[14]), .ZN(N22) );
  AND2_X2 C231 ( .A1(data_reg[15]), .A2(M_reg[15]), .ZN(N21) );
  AND2_X2 C230 ( .A1(data_reg[16]), .A2(M_reg[16]), .ZN(N20) );
  AND2_X2 C229 ( .A1(data_reg[17]), .A2(M_reg[17]), .ZN(N19) );
  AND2_X2 C228 ( .A1(data_reg[18]), .A2(M_reg[18]), .ZN(N18) );
  AND2_X2 C227 ( .A1(data_reg[19]), .A2(M_reg[19]), .ZN(N17) );
  AND2_X2 C226 ( .A1(data_reg[20]), .A2(M_reg[20]), .ZN(N16) );
  AND2_X2 C225 ( .A1(data_reg[21]), .A2(M_reg[21]), .ZN(N15) );
  AND2_X2 C224 ( .A1(data_reg[22]), .A2(M_reg[22]), .ZN(N14) );
  AND2_X2 C223 ( .A1(data_reg[23]), .A2(M_reg[23]), .ZN(N13) );
  AND2_X2 C222 ( .A1(data_reg[24]), .A2(M_reg[24]), .ZN(N12) );
  AND2_X2 C221 ( .A1(data_reg[25]), .A2(M_reg[25]), .ZN(N11) );
  AND2_X2 C220 ( .A1(data_reg[26]), .A2(M_reg[26]), .ZN(N10) );
  AND2_X2 C219 ( .A1(data_reg[27]), .A2(M_reg[27]), .ZN(N9) );
  AND2_X2 C218 ( .A1(data_reg[28]), .A2(M_reg[28]), .ZN(N8) );
  AND2_X2 C217 ( .A1(data_reg[29]), .A2(M_reg[29]), .ZN(N7) );
  AND2_X2 C216 ( .A1(data_reg[30]), .A2(M_reg[30]), .ZN(N6) );
  AND2_X2 C215 ( .A1(data_reg[31]), .A2(M_reg[31]), .ZN(N5) );
  OR2_X2 C213 ( .A1(addr_reg[0]), .A2(addr_reg[1]), .ZN(N69) );
  OR2_X2 C212 ( .A1(N69), .A2(addr_reg[2]), .ZN(N70) );
  OR2_X2 C211 ( .A1(N70), .A2(addr_reg[3]), .ZN(N71) );
  OR2_X2 C210 ( .A1(N71), .A2(addr_reg[4]), .ZN(N72) );
  OR2_X2 C209 ( .A1(N72), .A2(addr_reg[5]), .ZN(N73) );
  OR2_X2 C208 ( .A1(N73), .A2(addr_reg[6]), .ZN(N74) );
  OR2_X2 C207 ( .A1(N74), .A2(addr_reg[7]), .ZN(N75) );
  OR2_X2 C206 ( .A1(N75), .A2(addr_reg[8]), .ZN(N76) );
  OR2_X2 C205 ( .A1(N76), .A2(addr_reg[9]), .ZN(N77) );
  OR2_X2 C204 ( .A1(N77), .A2(addr_reg[10]), .ZN(N3) );
  DFF_X1 \M_reg_reg[31]  ( .D(bit_wen[31]), .CK(clk), .Q(M_reg[31]) );
  DFF_X1 \M_reg_reg[30]  ( .D(bit_wen[30]), .CK(clk), .Q(M_reg[30]) );
  DFF_X1 \M_reg_reg[29]  ( .D(bit_wen[29]), .CK(clk), .Q(M_reg[29]) );
  DFF_X1 \M_reg_reg[28]  ( .D(bit_wen[28]), .CK(clk), .Q(M_reg[28]) );
  DFF_X1 \M_reg_reg[27]  ( .D(bit_wen[27]), .CK(clk), .Q(M_reg[27]) );
  DFF_X1 \M_reg_reg[26]  ( .D(bit_wen[26]), .CK(clk), .Q(M_reg[26]) );
  DFF_X1 \M_reg_reg[25]  ( .D(bit_wen[25]), .CK(clk), .Q(M_reg[25]) );
  DFF_X1 \M_reg_reg[24]  ( .D(bit_wen[24]), .CK(clk), .Q(M_reg[24]) );
  DFF_X1 \M_reg_reg[23]  ( .D(bit_wen[23]), .CK(clk), .Q(M_reg[23]) );
  DFF_X1 \M_reg_reg[22]  ( .D(bit_wen[22]), .CK(clk), .Q(M_reg[22]) );
  DFF_X1 \M_reg_reg[21]  ( .D(bit_wen[21]), .CK(clk), .Q(M_reg[21]) );
  DFF_X1 \M_reg_reg[20]  ( .D(bit_wen[20]), .CK(clk), .Q(M_reg[20]) );
  DFF_X1 \M_reg_reg[19]  ( .D(bit_wen[19]), .CK(clk), .Q(M_reg[19]) );
  DFF_X1 \M_reg_reg[18]  ( .D(bit_wen[18]), .CK(clk), .Q(M_reg[18]) );
  DFF_X1 \M_reg_reg[17]  ( .D(bit_wen[17]), .CK(clk), .Q(M_reg[17]) );
  DFF_X1 \M_reg_reg[16]  ( .D(bit_wen[16]), .CK(clk), .Q(M_reg[16]) );
  DFF_X1 \M_reg_reg[15]  ( .D(bit_wen[15]), .CK(clk), .Q(M_reg[15]) );
  DFF_X1 \M_reg_reg[14]  ( .D(bit_wen[14]), .CK(clk), .Q(M_reg[14]) );
  DFF_X1 \M_reg_reg[13]  ( .D(bit_wen[13]), .CK(clk), .Q(M_reg[13]) );
  DFF_X1 \M_reg_reg[12]  ( .D(bit_wen[12]), .CK(clk), .Q(M_reg[12]) );
  DFF_X1 \M_reg_reg[11]  ( .D(bit_wen[11]), .CK(clk), .Q(M_reg[11]) );
  DFF_X1 \M_reg_reg[10]  ( .D(bit_wen[10]), .CK(clk), .Q(M_reg[10]) );
  DFF_X1 \M_reg_reg[9]  ( .D(bit_wen[9]), .CK(clk), .Q(M_reg[9]) );
  DFF_X1 \M_reg_reg[8]  ( .D(bit_wen[8]), .CK(clk), .Q(M_reg[8]) );
  DFF_X1 \M_reg_reg[7]  ( .D(bit_wen[7]), .CK(clk), .Q(M_reg[7]) );
  DFF_X1 \M_reg_reg[6]  ( .D(bit_wen[6]), .CK(clk), .Q(M_reg[6]) );
  DFF_X1 \M_reg_reg[5]  ( .D(bit_wen[5]), .CK(clk), .Q(M_reg[5]) );
  DFF_X1 \M_reg_reg[4]  ( .D(bit_wen[4]), .CK(clk), .Q(M_reg[4]) );
  DFF_X1 \M_reg_reg[3]  ( .D(bit_wen[3]), .CK(clk), .Q(M_reg[3]) );
  DFF_X1 \M_reg_reg[2]  ( .D(bit_wen[2]), .CK(clk), .Q(M_reg[2]) );
  DFF_X1 \M_reg_reg[1]  ( .D(bit_wen[1]), .CK(clk), .Q(M_reg[1]) );
  DFF_X1 \M_reg_reg[0]  ( .D(bit_wen[0]), .CK(clk), .Q(M_reg[0]) );
  DFF_X1 \addr_reg_reg[10]  ( .D(n132), .CK(clk), .Q(addr_reg[10]), .QN(n89)
         );
  DFF_X1 \addr_reg_reg[9]  ( .D(n131), .CK(clk), .Q(addr_reg[9]), .QN(n88) );
  DFF_X1 \addr_reg_reg[8]  ( .D(n130), .CK(clk), .Q(addr_reg[8]), .QN(n87) );
  DFF_X1 \addr_reg_reg[7]  ( .D(n129), .CK(clk), .Q(addr_reg[7]), .QN(n86) );
  DFF_X1 \addr_reg_reg[6]  ( .D(n128), .CK(clk), .Q(addr_reg[6]), .QN(n85) );
  DFF_X1 \addr_reg_reg[5]  ( .D(n127), .CK(clk), .Q(addr_reg[5]), .QN(n84) );
  DFF_X1 \addr_reg_reg[4]  ( .D(n126), .CK(clk), .Q(addr_reg[4]), .QN(n83) );
  DFF_X1 \addr_reg_reg[3]  ( .D(n125), .CK(clk), .Q(addr_reg[3]), .QN(n82) );
  DFF_X1 \addr_reg_reg[2]  ( .D(n124), .CK(clk), .Q(addr_reg[2]), .QN(n81) );
  DFF_X1 \addr_reg_reg[1]  ( .D(n123), .CK(clk), .Q(addr_reg[1]), .QN(n80) );
  DFF_X1 \addr_reg_reg[0]  ( .D(n122), .CK(clk), .Q(addr_reg[0]), .QN(n79) );
  DFF_X1 \data_reg_reg[31]  ( .D(n121), .CK(clk), .Q(data_reg[31]), .QN(n78)
         );
  DFF_X1 \data_reg_reg[30]  ( .D(n120), .CK(clk), .Q(data_reg[30]), .QN(n77)
         );
  DFF_X1 \data_reg_reg[29]  ( .D(n119), .CK(clk), .Q(data_reg[29]), .QN(n76)
         );
  DFF_X1 \data_reg_reg[28]  ( .D(n118), .CK(clk), .Q(data_reg[28]), .QN(n75)
         );
  DFF_X1 \data_reg_reg[27]  ( .D(n117), .CK(clk), .Q(data_reg[27]), .QN(n74)
         );
  DFF_X1 \data_reg_reg[26]  ( .D(n116), .CK(clk), .Q(data_reg[26]), .QN(n73)
         );
  DFF_X1 \data_reg_reg[25]  ( .D(n115), .CK(clk), .Q(data_reg[25]), .QN(n72)
         );
  DFF_X1 \data_reg_reg[24]  ( .D(n114), .CK(clk), .Q(data_reg[24]), .QN(n71)
         );
  DFF_X1 \data_reg_reg[23]  ( .D(n113), .CK(clk), .Q(data_reg[23]), .QN(n70)
         );
  DFF_X1 \data_reg_reg[22]  ( .D(n112), .CK(clk), .Q(data_reg[22]), .QN(n69)
         );
  DFF_X1 \data_reg_reg[21]  ( .D(n111), .CK(clk), .Q(data_reg[21]), .QN(n68)
         );
  DFF_X1 \data_reg_reg[20]  ( .D(n110), .CK(clk), .Q(data_reg[20]), .QN(n67)
         );
  DFF_X1 \data_reg_reg[19]  ( .D(n109), .CK(clk), .Q(data_reg[19]), .QN(n66)
         );
  DFF_X1 \data_reg_reg[18]  ( .D(n108), .CK(clk), .Q(data_reg[18]), .QN(n65)
         );
  DFF_X1 \data_reg_reg[17]  ( .D(n107), .CK(clk), .Q(data_reg[17]), .QN(n64)
         );
  DFF_X1 \data_reg_reg[16]  ( .D(n106), .CK(clk), .Q(data_reg[16]), .QN(n63)
         );
  DFF_X1 \data_reg_reg[15]  ( .D(n105), .CK(clk), .Q(data_reg[15]), .QN(n62)
         );
  DFF_X1 \data_reg_reg[14]  ( .D(n104), .CK(clk), .Q(data_reg[14]), .QN(n61)
         );
  DFF_X1 \data_reg_reg[13]  ( .D(n103), .CK(clk), .Q(data_reg[13]), .QN(n60)
         );
  DFF_X1 \data_reg_reg[12]  ( .D(n102), .CK(clk), .Q(data_reg[12]), .QN(n59)
         );
  DFF_X1 \data_reg_reg[11]  ( .D(n101), .CK(clk), .Q(data_reg[11]), .QN(n58)
         );
  DFF_X1 \data_reg_reg[10]  ( .D(n100), .CK(clk), .Q(data_reg[10]), .QN(n57)
         );
  DFF_X1 \data_reg_reg[9]  ( .D(n99), .CK(clk), .Q(data_reg[9]), .QN(n56) );
  DFF_X1 \data_reg_reg[8]  ( .D(n98), .CK(clk), .Q(data_reg[8]), .QN(n55) );
  DFF_X1 \data_reg_reg[7]  ( .D(n97), .CK(clk), .Q(data_reg[7]), .QN(n54) );
  DFF_X1 \data_reg_reg[6]  ( .D(n96), .CK(clk), .Q(data_reg[6]), .QN(n53) );
  DFF_X1 \data_reg_reg[5]  ( .D(n95), .CK(clk), .Q(data_reg[5]), .QN(n52) );
  DFF_X1 \data_reg_reg[4]  ( .D(n94), .CK(clk), .Q(data_reg[4]), .QN(n51) );
  DFF_X1 \data_reg_reg[3]  ( .D(n93), .CK(clk), .Q(data_reg[3]), .QN(n50) );
  DFF_X1 \data_reg_reg[2]  ( .D(n92), .CK(clk), .Q(data_reg[2]), .QN(n49) );
  DFF_X1 \data_reg_reg[1]  ( .D(n91), .CK(clk), .Q(data_reg[1]), .QN(n48) );
  DFF_X1 \data_reg_reg[0]  ( .D(n90), .CK(clk), .Q(data_reg[0]), .QN(n47) );
  OAI22_X1 U3 ( .A1(n47), .A2(n2), .B1(n199), .B2(n3), .ZN(n90) );
  INV_X1 U4 ( .A(data_in[0]), .ZN(n3) );
  OAI22_X1 U5 ( .A1(n2), .A2(n48), .B1(n199), .B2(n4), .ZN(n91) );
  INV_X1 U6 ( .A(data_in[1]), .ZN(n4) );
  OAI22_X1 U7 ( .A1(n2), .A2(n49), .B1(n199), .B2(n5), .ZN(n92) );
  INV_X1 U8 ( .A(data_in[2]), .ZN(n5) );
  OAI22_X1 U9 ( .A1(n2), .A2(n50), .B1(n199), .B2(n6), .ZN(n93) );
  INV_X1 U10 ( .A(data_in[3]), .ZN(n6) );
  OAI22_X1 U11 ( .A1(n2), .A2(n51), .B1(n199), .B2(n7), .ZN(n94) );
  INV_X1 U12 ( .A(data_in[4]), .ZN(n7) );
  OAI22_X1 U13 ( .A1(n2), .A2(n52), .B1(n199), .B2(n8), .ZN(n95) );
  INV_X1 U14 ( .A(data_in[5]), .ZN(n8) );
  OAI22_X1 U15 ( .A1(n2), .A2(n53), .B1(n199), .B2(n9), .ZN(n96) );
  INV_X1 U16 ( .A(data_in[6]), .ZN(n9) );
  OAI22_X1 U17 ( .A1(n2), .A2(n54), .B1(n199), .B2(n10), .ZN(n97) );
  INV_X1 U18 ( .A(data_in[7]), .ZN(n10) );
  OAI22_X1 U19 ( .A1(n2), .A2(n55), .B1(n199), .B2(n11), .ZN(n98) );
  INV_X1 U20 ( .A(data_in[8]), .ZN(n11) );
  OAI22_X1 U21 ( .A1(n2), .A2(n56), .B1(n199), .B2(n12), .ZN(n99) );
  INV_X1 U22 ( .A(data_in[9]), .ZN(n12) );
  OAI22_X1 U23 ( .A1(n2), .A2(n57), .B1(n199), .B2(n13), .ZN(n100) );
  INV_X1 U24 ( .A(data_in[10]), .ZN(n13) );
  OAI22_X1 U25 ( .A1(n2), .A2(n58), .B1(n199), .B2(n14), .ZN(n101) );
  INV_X1 U26 ( .A(data_in[11]), .ZN(n14) );
  OAI22_X1 U27 ( .A1(n2), .A2(n59), .B1(n199), .B2(n15), .ZN(n102) );
  INV_X1 U28 ( .A(data_in[12]), .ZN(n15) );
  OAI22_X1 U29 ( .A1(n2), .A2(n60), .B1(n199), .B2(n16), .ZN(n103) );
  INV_X1 U30 ( .A(data_in[13]), .ZN(n16) );
  OAI22_X1 U31 ( .A1(n2), .A2(n61), .B1(n199), .B2(n17), .ZN(n104) );
  INV_X1 U32 ( .A(data_in[14]), .ZN(n17) );
  OAI22_X1 U33 ( .A1(n2), .A2(n62), .B1(n199), .B2(n18), .ZN(n105) );
  INV_X1 U34 ( .A(data_in[15]), .ZN(n18) );
  OAI22_X1 U35 ( .A1(n2), .A2(n63), .B1(n199), .B2(n19), .ZN(n106) );
  INV_X1 U36 ( .A(data_in[16]), .ZN(n19) );
  OAI22_X1 U37 ( .A1(n2), .A2(n64), .B1(n199), .B2(n20), .ZN(n107) );
  INV_X1 U38 ( .A(data_in[17]), .ZN(n20) );
  OAI22_X1 U39 ( .A1(n2), .A2(n65), .B1(n199), .B2(n21), .ZN(n108) );
  INV_X1 U40 ( .A(data_in[18]), .ZN(n21) );
  OAI22_X1 U41 ( .A1(n2), .A2(n66), .B1(n199), .B2(n22), .ZN(n109) );
  INV_X1 U42 ( .A(data_in[19]), .ZN(n22) );
  OAI22_X1 U43 ( .A1(n2), .A2(n67), .B1(n199), .B2(n23), .ZN(n110) );
  INV_X1 U44 ( .A(data_in[20]), .ZN(n23) );
  OAI22_X1 U45 ( .A1(n2), .A2(n68), .B1(n199), .B2(n24), .ZN(n111) );
  INV_X1 U46 ( .A(data_in[21]), .ZN(n24) );
  OAI22_X1 U47 ( .A1(n2), .A2(n69), .B1(n199), .B2(n25), .ZN(n112) );
  INV_X1 U48 ( .A(data_in[22]), .ZN(n25) );
  OAI22_X1 U49 ( .A1(n2), .A2(n70), .B1(n199), .B2(n26), .ZN(n113) );
  INV_X1 U50 ( .A(data_in[23]), .ZN(n26) );
  OAI22_X1 U51 ( .A1(n2), .A2(n71), .B1(n199), .B2(n27), .ZN(n114) );
  INV_X1 U52 ( .A(data_in[24]), .ZN(n27) );
  OAI22_X1 U53 ( .A1(n2), .A2(n72), .B1(n199), .B2(n28), .ZN(n115) );
  INV_X1 U54 ( .A(data_in[25]), .ZN(n28) );
  OAI22_X1 U55 ( .A1(n2), .A2(n73), .B1(n199), .B2(n29), .ZN(n116) );
  INV_X1 U56 ( .A(data_in[26]), .ZN(n29) );
  OAI22_X1 U57 ( .A1(n2), .A2(n74), .B1(n199), .B2(n30), .ZN(n117) );
  INV_X1 U58 ( .A(data_in[27]), .ZN(n30) );
  OAI22_X1 U59 ( .A1(n2), .A2(n75), .B1(n199), .B2(n31), .ZN(n118) );
  INV_X1 U60 ( .A(data_in[28]), .ZN(n31) );
  OAI22_X1 U61 ( .A1(n2), .A2(n76), .B1(n199), .B2(n32), .ZN(n119) );
  INV_X1 U62 ( .A(data_in[29]), .ZN(n32) );
  OAI22_X1 U63 ( .A1(n2), .A2(n77), .B1(n199), .B2(n33), .ZN(n120) );
  INV_X1 U64 ( .A(data_in[30]), .ZN(n33) );
  OAI22_X1 U65 ( .A1(n2), .A2(n78), .B1(n199), .B2(n34), .ZN(n121) );
  INV_X1 U66 ( .A(data_in[31]), .ZN(n34) );
  OAI22_X1 U68 ( .A1(n198), .A2(n35), .B1(n79), .B2(n36), .ZN(n122) );
  INV_X1 U69 ( .A(address[0]), .ZN(n35) );
  OAI22_X1 U70 ( .A1(n198), .A2(n37), .B1(n36), .B2(n80), .ZN(n123) );
  INV_X1 U71 ( .A(address[1]), .ZN(n37) );
  OAI22_X1 U72 ( .A1(n198), .A2(n38), .B1(n36), .B2(n81), .ZN(n124) );
  INV_X1 U73 ( .A(address[2]), .ZN(n38) );
  OAI22_X1 U74 ( .A1(n198), .A2(n39), .B1(n36), .B2(n82), .ZN(n125) );
  INV_X1 U75 ( .A(address[3]), .ZN(n39) );
  OAI22_X1 U76 ( .A1(n198), .A2(n40), .B1(n36), .B2(n83), .ZN(n126) );
  INV_X1 U77 ( .A(address[4]), .ZN(n40) );
  OAI22_X1 U78 ( .A1(n198), .A2(n41), .B1(n36), .B2(n84), .ZN(n127) );
  INV_X1 U79 ( .A(address[5]), .ZN(n41) );
  OAI22_X1 U80 ( .A1(n198), .A2(n42), .B1(n36), .B2(n85), .ZN(n128) );
  INV_X1 U81 ( .A(address[6]), .ZN(n42) );
  OAI22_X1 U82 ( .A1(n198), .A2(n43), .B1(n36), .B2(n86), .ZN(n129) );
  INV_X1 U83 ( .A(address[7]), .ZN(n43) );
  OAI22_X1 U84 ( .A1(n198), .A2(n44), .B1(n36), .B2(n87), .ZN(n130) );
  INV_X1 U85 ( .A(address[8]), .ZN(n44) );
  OAI22_X1 U86 ( .A1(n198), .A2(n45), .B1(n36), .B2(n88), .ZN(n131) );
  INV_X1 U87 ( .A(address[9]), .ZN(n45) );
  OAI22_X1 U88 ( .A1(n198), .A2(n46), .B1(n36), .B2(n89), .ZN(n132) );
  INV_X1 U89 ( .A(n198), .ZN(n36) );
  INV_X1 U90 ( .A(address[10]), .ZN(n46) );
  INV_X1 U91 ( .A(n165), .ZN(data_out[9]) );
  AOI22_X1 U92 ( .A1(N3), .A2(N27), .B1(N59), .B2(n166), .ZN(n165) );
  INV_X1 U93 ( .A(n167), .ZN(data_out[8]) );
  AOI22_X1 U94 ( .A1(N28), .A2(N3), .B1(N60), .B2(n166), .ZN(n167) );
  INV_X1 U95 ( .A(n168), .ZN(data_out[7]) );
  AOI22_X1 U96 ( .A1(N29), .A2(N3), .B1(N61), .B2(n166), .ZN(n168) );
  INV_X1 U97 ( .A(n169), .ZN(data_out[6]) );
  AOI22_X1 U98 ( .A1(N62), .A2(n166), .B1(N30), .B2(N3), .ZN(n169) );
  INV_X1 U99 ( .A(n170), .ZN(data_out[5]) );
  AOI22_X1 U100 ( .A1(N63), .A2(n166), .B1(N31), .B2(N3), .ZN(n170) );
  INV_X1 U101 ( .A(n171), .ZN(data_out[4]) );
  AOI22_X1 U102 ( .A1(N64), .A2(n166), .B1(N32), .B2(N3), .ZN(n171) );
  INV_X1 U103 ( .A(n172), .ZN(data_out[3]) );
  AOI22_X1 U104 ( .A1(N65), .A2(n166), .B1(N33), .B2(N3), .ZN(n172) );
  INV_X1 U105 ( .A(n173), .ZN(data_out[31]) );
  AOI22_X1 U106 ( .A1(N37), .A2(n166), .B1(N5), .B2(N3), .ZN(n173) );
  INV_X1 U107 ( .A(n174), .ZN(data_out[30]) );
  AOI22_X1 U108 ( .A1(N38), .A2(n166), .B1(N6), .B2(N3), .ZN(n174) );
  INV_X1 U109 ( .A(n175), .ZN(data_out[2]) );
  AOI22_X1 U110 ( .A1(N66), .A2(n166), .B1(N34), .B2(N3), .ZN(n175) );
  INV_X1 U111 ( .A(n176), .ZN(data_out[29]) );
  AOI22_X1 U112 ( .A1(N39), .A2(n166), .B1(N7), .B2(N3), .ZN(n176) );
  INV_X1 U113 ( .A(n177), .ZN(data_out[28]) );
  AOI22_X1 U114 ( .A1(N40), .A2(n166), .B1(N8), .B2(N3), .ZN(n177) );
  INV_X1 U115 ( .A(n178), .ZN(data_out[27]) );
  AOI22_X1 U116 ( .A1(N41), .A2(n166), .B1(N9), .B2(N3), .ZN(n178) );
  INV_X1 U117 ( .A(n179), .ZN(data_out[26]) );
  AOI22_X1 U118 ( .A1(N10), .A2(N3), .B1(N42), .B2(n166), .ZN(n179) );
  INV_X1 U119 ( .A(n180), .ZN(data_out[25]) );
  AOI22_X1 U120 ( .A1(N11), .A2(N3), .B1(N43), .B2(n166), .ZN(n180) );
  INV_X1 U121 ( .A(n181), .ZN(data_out[24]) );
  AOI22_X1 U122 ( .A1(N12), .A2(N3), .B1(N44), .B2(n166), .ZN(n181) );
  INV_X1 U123 ( .A(n182), .ZN(data_out[23]) );
  AOI22_X1 U124 ( .A1(N13), .A2(N3), .B1(N45), .B2(n166), .ZN(n182) );
  INV_X1 U125 ( .A(n183), .ZN(data_out[22]) );
  AOI22_X1 U126 ( .A1(N14), .A2(N3), .B1(N46), .B2(n166), .ZN(n183) );
  INV_X1 U127 ( .A(n184), .ZN(data_out[21]) );
  AOI22_X1 U128 ( .A1(N15), .A2(N3), .B1(N47), .B2(n166), .ZN(n184) );
  INV_X1 U129 ( .A(n185), .ZN(data_out[20]) );
  AOI22_X1 U130 ( .A1(N16), .A2(N3), .B1(N48), .B2(n166), .ZN(n185) );
  INV_X1 U131 ( .A(n186), .ZN(data_out[1]) );
  AOI22_X1 U132 ( .A1(N67), .A2(n166), .B1(N35), .B2(N3), .ZN(n186) );
  INV_X1 U133 ( .A(n187), .ZN(data_out[19]) );
  AOI22_X1 U134 ( .A1(N17), .A2(N3), .B1(N49), .B2(n166), .ZN(n187) );
  INV_X1 U135 ( .A(n188), .ZN(data_out[18]) );
  AOI22_X1 U136 ( .A1(N18), .A2(N3), .B1(N50), .B2(n166), .ZN(n188) );
  INV_X1 U137 ( .A(n189), .ZN(data_out[17]) );
  AOI22_X1 U138 ( .A1(N19), .A2(N3), .B1(N51), .B2(n166), .ZN(n189) );
  INV_X1 U139 ( .A(n190), .ZN(data_out[16]) );
  AOI22_X1 U140 ( .A1(N20), .A2(N3), .B1(N52), .B2(n166), .ZN(n190) );
  INV_X1 U141 ( .A(n191), .ZN(data_out[15]) );
  AOI22_X1 U142 ( .A1(N21), .A2(N3), .B1(N53), .B2(n166), .ZN(n191) );
  INV_X1 U143 ( .A(n192), .ZN(data_out[14]) );
  AOI22_X1 U144 ( .A1(N22), .A2(N3), .B1(N54), .B2(n166), .ZN(n192) );
  INV_X1 U145 ( .A(n193), .ZN(data_out[13]) );
  AOI22_X1 U146 ( .A1(N23), .A2(N3), .B1(N55), .B2(n166), .ZN(n193) );
  INV_X1 U147 ( .A(n194), .ZN(data_out[12]) );
  AOI22_X1 U148 ( .A1(N24), .A2(N3), .B1(N56), .B2(n166), .ZN(n194) );
  INV_X1 U149 ( .A(n195), .ZN(data_out[11]) );
  AOI22_X1 U150 ( .A1(N25), .A2(N3), .B1(N57), .B2(n166), .ZN(n195) );
  INV_X1 U151 ( .A(n196), .ZN(data_out[10]) );
  AOI22_X1 U152 ( .A1(N26), .A2(N3), .B1(N58), .B2(n166), .ZN(n196) );
  INV_X1 U153 ( .A(n197), .ZN(data_out[0]) );
  AOI22_X1 U154 ( .A1(N68), .A2(n166), .B1(N36), .B2(N3), .ZN(n197) );
  CLKBUF_X1 U156 ( .A(rdn), .Z(n198) );
  CLKBUF_X2 U157 ( .A(wrn), .Z(n199) );
  INV_X2 U158 ( .A(N3), .ZN(n166) );
  INV_X2 U159 ( .A(n199), .ZN(n2) );
endmodule

