
const express = require("express");
const bodyParser = require("body-parser");
const mysql = require("mysql2");
const cors = require("cors");
const path = require("path");
const axios = require("axios"); // HTTP 요청을 위해 axios 패키지 사용

const app = express();
const PORT = 3000;

console.log("Starting server.js from flutter_google_map_sample directory");

// Middleware 설정
app.use(cors()); // Cross-Origin Resource Sharing 허용
app.use(bodyParser.json()); // JSON 데이터 파싱

console.log("Static files served from:", path.join(__dirname, "website"));
console.log("HTML 반환 경로:", path.join(__dirname, "website", "storeRegister3.html"));


// 🔥 정적 파일 서빙 설정 추가
// 'website' 디렉토리를 정적 파일 경로로 설정
app.use(express.static(path.join(__dirname, "website"))); // 정적 파일 서빙 (HTML, CSS, JS)

console.log("HTML 파일 경로:", path.join(__dirname, "website", "storeRegister3.html"));

// 기본 파일 설정: http://localhost:3000/ 요청 시 storeRegister3.html 반환
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "website", "storeRegister3.html"));
});

// MySQL Database 연결 설정
const db = mysql.createConnection({
  host: "localhost",
  user: "root",
  password: "root768!", // MySQL 비밀번호
  database: "QuickOrder", // 데이터베이스 이름
  port: 3306, // 필요시 변경
});

// MySQL 연결
db.connect((err) => {
  if (err) {
    console.error("MySQL 연결 실패:", err);
    process.exit(1);
  }
  console.log("MySQL 연결 성공");
});

// (1) POS기 앱으로부터 데이터 수신
app.post("/crowd_level", (req, res) => {
  const { restaurant_ID, occupied_seats, total_seats } = req.body;

  if (!restaurant_ID|| !occupied_seats || !total_seats) {
    return res.status(400).send("데이터 형식이 올바르지 않습니다.");
  }

  // 혼잡도 계산
  const crowdLevelRatio = occupied_seats / total_seats;
  let crowd_level;

  if (crowdLevelRatio <= 0.5) {
    crowd_level = "green";
  } else if (crowdLevelRatio > 0.5 && crowdLevelRatio <= 0.75) {
    crowd_level = "yellow";
  } else if (crowdLevelRatio > 0.75 && crowdLevelRatio < 1.0) {
    crowd_level = "orange";
  } else if (crowdLevelRatio === 1.0) {
    crowd_level = "red";
  } else {
    return res.status(400).send("혼잡도 계산 실패: 잘못된 값");
  }

  // 데이터베이스 업데이트
  const query = "UPDATE restaurants SET crowd_level = ? WHERE restaurant_ID = ?";
  db.query(query, [crowd_level, restaurant_ID], (err, result) => {
    if (err) {
      console.error("데이터베이스 업데이트 실패:", err);
      return res.status(500).send("데이터베이스 업데이트 실패");
    }

    console.log(`Restaurant ID: ${restaurant_ID}, Crowd Level: ${crowd_level}`);
    res.status(200).send("혼잡도 업데이트 성공");
  });
});


// (2) HTML 폼 데이터 수신 및 DB에 저장
app.post("/register", (req, res) => {
  // 클라이언트로부터 전달된 데이터 추출
  const { restaurant_name, restaurant_address, table_1, table_2, table_4, table_8 } = req.body;

  // 총 좌석 수 계산
  const total_seats = table_1 + table_2 * 2 + table_4 * 4 + table_8 * 8;

  // MySQL INSERT 쿼리 실행
  const query =
    "INSERT INTO restaurants (restaurant_name, restaurant_address, total_seats) VALUES (?, ?, ?)";
  db.query(query, [restaurant_name, restaurant_address, total_seats], (err, result) => {
    if (err) {
      console.error("데이터베이스 삽입 실패:", err);
      return res.status(500).send("데이터베이스 삽입 실패");
    }
    console.log("데이터 삽입 성공:", result);
    res.status(200).send("식당 정보가 성공적으로 저장되었습니다.");
  });
});

/* chatGPT의 예전 코드
// (4) Flutter iOS 앱에 데이터 제공
app.get("/restaurants", (req, res) => {
  // MySQL SELECT 쿼리 실행
  const query = "SELECT restaurant_name, restaurant_address, crowd_level FROM restaurants";
  db.query(query, (err, results) => {
    if (err) {
      console.error("데이터베이스 조회 실패:", err);
      return res.status(500).send("데이터베이스 조회 실패");
    }
    // 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥이거 해결🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
    // crowd_level 계산 (총 좌석 수의 10%)
    const responseData = results.map((row) => ({
      restaurant_name: row.restaurant_name,
      restaurant_address: row.restaurant_address,
      crowd_level: Math.floor(row.total_seats * 0.1), // 예시 계산
    }));

    res.status(200).json(responseData);
  });
});
*/


// 메뉴 전달 기능 추가. 241219
// (4) Flutter iOS 앱에 데이터 제공 (수정 버전)
app.get("/restaurants", (req, res) => {
  const query = `
    SELECT 
      restaurant_name, 
      restaurant_address, 
      crowd_level, 
      IFNULL(menu1, '메뉴 정보 없음') AS menu1,
      IFNULL(menu2, '메뉴 정보 없음') AS menu2,
      IFNULL(menu3, '메뉴 정보 없음') AS menu3,
      IFNULL(menu4, '메뉴 정보 없음') AS menu4,
      IFNULL(menu5, '메뉴 정보 없음') AS menu5 
    FROM restaurants
  `;
  db.query(query, (err, results) => {
    if (err) {
      console.error("데이터베이스 조회 실패:", err);
      return res.status(500).send("데이터베이스 조회 실패");
    }
    const responseData = results.map((row) => ({
      restaurant_name: row.restaurant_name,
      restaurant_address: row.restaurant_address,
      crowd_level: row.crowd_level,
      menu1: row.menu1,
      menu2: row.menu2,
      menu3: row.menu3,
      menu4: row.menu4,
      menu5: row.menu5,
    }));
    res.status(200).json(responseData);
  });
});






// (6)
// POS기 앱의 상태로 사용할 객체
let currentOrder = null;

// Flutter 앱에서 주문 데이터 수신
app.post("/order", (req, res) => {
  const { user_ID, restaurant_ID, menus, headcount } = req.body;

  if (!user_ID || !restaurant_ID || !menus || headcount === undefined) {
    return res.status(400).send("주문 데이터 형식이 올바르지 않습니다.");
  }

  // 주문 데이터를 저장
  currentOrder = {
    user_ID,
    restaurant_ID,
    menus,
    headcount,
  };

  console.log("새 주문 데이터 수신:", currentOrder);
  res.status(200).send("주문 데이터가 성공적으로 저장되었습니다.");
});

// POS기 앱에서 현재 주문 데이터를 가져오기
app.get("/current_order", (req, res) => {
  if (currentOrder) {
    res.status(200).json(currentOrder);
  } else {
    res.status(404).send("현재 주문 데이터가 없습니다.");
  }
});

/*

// (6) Flutter 앱으로부터 '주문 내역' 수신 및 POS기 앱으로 전달
app.post("/order", async (req, res) => {
  const { user_ID, restaurant_ID, menus, headcount } = req.body;

  // 데이터 유효성 검사
  if (
    !user_ID ||
    !restaurant_ID ||
    !menus ||
    !Array.isArray(menus) ||
    menus.length === 0 ||
    headcount === undefined
  ) {
    return res.status(400).send("주문 데이터 형식이 올바르지 않습니다.");
  }

  // 메뉴 데이터를 로깅
  console.log("받은 주문 데이터:", req.body);


  // POS기 앱의 URL (IP 및 포트 번호는 환경에 따라 설정)
  const POS_URL = "http://localhost:3000/reservation"; // POS기 앱 주소

  

  try {
    // POS기 앱으로 주문 내역 전달
    const response = await axios.post(POS_URL, {
      user_ID,
      restaurant_ID,
      menus,
      headcount,
    });

    console.log("POS기 앱으로 주문 전송 성공:", response.data);

    // Flutter 앱에 성공 응답
    res.status(200).send("주문 데이터가 POS기로 성공적으로 전송되었습니다.");
  } catch (error) {
    console.error("POS기 앱으로 주문 전송 실패:", error.message);

    // Flutter 앱에 실패 응답
    res.status(500).send("POS기로 주문 데이터를 전송하는 중 오류가 발생했습니다.");
  }
});
*/




/* 기존 코드. 졸전 코드.
// 코드 내가 들여다보고, 바꿈.
// (4) Flutter iOS 앱에 데이터 제공
app.get("/restaurants", (req, res) => {
  // MySQL SELECT 쿼리 실행
  const query = "SELECT restaurant_name, restaurant_address, crowd_level FROM restaurants";
  db.query(query, (err, results) => {
    if (err) {
      console.error("데이터베이스 조회 실패:", err);
      return res.status(500).send("데이터베이스 조회 실패");
    }
    
    // 데이터베이스에서 crowd_level을 그대로 사용
    const responseData = results.map((row) => ({
      restaurant_name: row.restaurant_name,
      restaurant_address: row.restaurant_address,
      crowd_level: row.crowd_level, // ENUM 값 그대로 사용
    }));

    res.status(200).json(responseData);
  });
});
*/




// 예약 수락 처리
app.post("/reservation_accepted", (req, res) => {
  const { user_ID, restaurant_ID } = req.body;

  if (!user_ID || !restaurant_ID) {
    return res.status(400).send("잘못된 데이터 형식입니다.");
  }

  if (!currentOrder || currentOrder.user_ID !== user_ID || currentOrder.restaurant_ID !== restaurant_ID) {
    return res.status(404).send("현재 주문 데이터와 일치하지 않습니다.");
  }

  reservationStatus = "accepted"; // 상태 업데이트
  console.log(`Reservation accepted for user: ${user_ID}, restaurant: ${restaurant_ID}`);
  res.status(200).send("Reservation accepted notification stored.");
});

// 예약 거절 처리
app.post("/reservation_denied", (req, res) => {
  const { user_ID, restaurant_ID } = req.body;

  if (!user_ID || !restaurant_ID) {
    return res.status(400).send("잘못된 데이터 형식입니다.");
  }

  if (!currentOrder || currentOrder.user_ID !== user_ID || currentOrder.restaurant_ID !== restaurant_ID) {
    return res.status(404).send("현재 주문 데이터와 일치하지 않습니다.");
  }

  reservationStatus = "denied"; // 상태 업데이트
  console.log(`Reservation denied for user: ${user_ID}, restaurant: ${restaurant_ID}`);
  res.status(200).send("Reservation denied notification stored.");
});

// Flutter 앱에서 예약 상태 가져오기
app.get("/reservation_status", (req, res) => {
  if (reservationStatus) {
    res.status(200).json({ status: reservationStatus });
  } else {
    res.status(404).send("예약 상태가 설정되지 않았습니다.");
  }
});



// 서버 시작
app.listen(PORT, () => {
  console.log(`서버가 http://localhost:${PORT} 에서 실행 중입니다.`);
});












/*
const express = require("express");
const bodyParser = require("body-parser");
const mysql = require("mysql2");
const cors = require("cors");
const path = require("path");

const app = express();
const PORT = 3000;

console.log("Starting server.js from flutter_google_map_sample directory");

// Middleware 설정
app.use(cors()); // Cross-Origin Resource Sharing 허용
app.use(bodyParser.json()); // JSON 데이터 파싱

console.log("Static files served from:", path.join(__dirname, "website"));
console.log("HTML 반환 경로:", path.join(__dirname, "website", "storeRegister3.html"));


// 🔥 정적 파일 서빙 설정 추가
// 'website' 디렉토리를 정적 파일 경로로 설정
app.use(express.static(path.join(__dirname, "website"))); // 정적 파일 서빙 (HTML, CSS, JS)

console.log("HTML 파일 경로:", path.join(__dirname, "website", "storeRegister3.html"));

// 기본 파일 설정: http://localhost:3000/ 요청 시 storeRegister3.html 반환
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "website", "storeRegister3.html"));
});

// MySQL Database 연결 설정
const db = mysql.createConnection({
  host: "localhost",
  user: "root",
  password: "root768!", // MySQL 비밀번호
  database: "QuickOrder", // 데이터베이스 이름
  port: 3306, // 필요시 변경
});

// MySQL 연결
db.connect((err) => {
  if (err) {
    console.error("MySQL 연결 실패:", err);
    process.exit(1);
  }
  console.log("MySQL 연결 성공");
});

// (1) POS기 앱으로부터 데이터 수신
app.post("/crowd_level", (req, res) => {
  const { restaurantId, occupiedSeats, totalSeats } = req.body;

  if (!restaurantId || !occupiedSeats || !totalSeats) {
    return res.status(400).send("데이터 형식이 올바르지 않습니다.");
  }

  // 혼잡도 계산
  const crowdLevelRatio = occupiedSeats / totalSeats;
  let crowdLevel;

  if (crowdLevelRatio <= 0.5) {
    crowdLevel = "green";
  } else if (crowdLevelRatio > 0.5 && crowdLevelRatio <= 0.75) {
    crowdLevel = "yellow";
  } else if (crowdLevelRatio > 0.75 && crowdLevelRatio < 1.0) {
    crowdLevel = "orange";
  } else if (crowdLevelRatio === 1.0) {
    crowdLevel = "red";
  } else {
    return res.status(400).send("혼잡도 계산 실패: 잘못된 값");
  }

  // 데이터베이스 업데이트
  const query = "UPDATE restaurants SET crowd_level = ? WHERE id = ?";
  db.query(query, [crowdLevel, restaurantId], (err, result) => {
    if (err) {
      console.error("데이터베이스 업데이트 실패:", err);
      return res.status(500).send("데이터베이스 업데이트 실패");
    }

    console.log(`Restaurant ID: ${restaurantId}, Crowd Level: ${crowdLevel}`);
    res.status(200).send("혼잡도 업데이트 성공");
  });
});


// (2) HTML 폼 데이터 수신 및 DB에 저장
app.post("/register", (req, res) => {
  // 클라이언트로부터 전달된 데이터 추출
  const { restaurant_name, restaurant_address, table_1, table_2, table_4, table_8 } = req.body;

  // 총 좌석 수 계산
  const total_seats = table_1 + table_2 * 2 + table_4 * 4 + table_8 * 8;

  // MySQL INSERT 쿼리 실행
  const query =
    "INSERT INTO restaurants (restaurant_name, restaurant_address, total_seats) VALUES (?, ?, ?)";
  db.query(query, [restaurant_name, restaurant_address, total_seats], (err, result) => {
    if (err) {
      console.error("데이터베이스 삽입 실패:", err);
      return res.status(500).send("데이터베이스 삽입 실패");
    }
    console.log("데이터 삽입 성공:", result);
    res.status(200).send("식당 정보가 성공적으로 저장되었습니다.");
  });
});



// 코드 내가 들여다보고, 바꿈.
// (4) Flutter iOS 앱에 데이터 제공
app.get("/restaurants", (req, res) => {
  // MySQL SELECT 쿼리 실행
  const query = "SELECT restaurant_name, restaurant_address, crowd_level FROM restaurants";
  db.query(query, (err, results) => {
    if (err) {
      console.error("데이터베이스 조회 실패:", err);
      return res.status(500).send("데이터베이스 조회 실패");
    }
    
    // 데이터베이스에서 crowd_level을 그대로 사용
    const responseData = results.map((row) => ({
      restaurant_name: row.restaurant_name,
      restaurant_address: row.restaurant_address,
      crowd_level: row.crowd_level, // ENUM 값 그대로 사용
    }));

    res.status(200).json(responseData);
  });
});






// 서버 시작
app.listen(PORT, () => {
  console.log(`서버가 http://localhost:${PORT} 에서 실행 중입니다.`);
});


*/
