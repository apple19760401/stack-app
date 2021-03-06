//
//  MainVC.swift
//  stack-app
//
//  Created by 김부성 on 2/7/21.
//

import UIKit

import Alamofire
import KDCircularProgress
import Then

let bluecolor = #colorLiteral(red: 0.2705882353, green: 0.4431372549, blue: 0.9019607843, alpha: 1)
let redcolor = #colorLiteral(red: 0.9529411765, green: 0.3254901961, blue: 0.3254901961, alpha: 1)

class MainVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var circleChart: KDCircularProgress!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var pointButton: UIBarItem!
    @IBOutlet weak var pointLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    lazy var alert = UIAlertController(title: "네트워크 오류", message: "네트워크를 다시 확인해주세요!", preferredStyle: .alert).then {
        $0.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
    }
    
    var data:Point?
    // 상점 벌점
    var point: Double = 0
    // 차트 최고점
    let maxpoint: Double = 50
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "상점"
        // 처음 원형차트의 퍼센트를 0으로 초기화
        circleChart.angle = 0
        //테이블 뷰의 선택을 막음
        tableView.allowsSelection = false
        //원형이미지 출력
        circleimage()
        // tableview의 모서리 지정
        self.tableView.layer.cornerRadius = 10
        // 뷰가 생성 될 때 상점을 로드
        networking(type: 0) {
            self.pointLabel.text = "\(Int(self.point))점"
            self.drawChart(self.point)
            self.numberLabel.text = String((self.data?.data.user[0].number)!)
            self.nameLabel.text = self.data?.data.user[0].name
            self.tableView.reloadData()
        }
        // Do any additional setup after loading the view.
    }
    
    // 상점, 벌점 전환 함수
    @IBAction func pointButton(_ sender: Any) {
        if title == "상점" {
            title = "벌점"
            pointButton.title = "상점"
            circleChart.set(colors: redcolor)
            networking(type: 1) {
                self.drawChart(self.point)
                self.tableView.reloadData()
                self.pointLabel.text = "\(Int(self.point))점"
            }
        }
        else {
            title = "상점"
            pointButton.title = "벌점"
            circleChart.set(colors: bluecolor)
            networking(type: 0) {
                self.drawChart(self.point)
                self.tableView.reloadData()
                self.pointLabel.text = "\(Int(self.point))점"
            }
        }
    }
    
    // 네트워크 관련 함수
    private func networking(type: Int, complition: @escaping () -> Void) {
        
        // 네트워크 url, 헤더, queryparameter 설정
        let uri = "/point"
        let headers:HTTPHeaders = ["authorization" : "\(Token.shared.token ?? "")"]
        let parameters: Parameters = ["type": type]
        
        NetworkingMock.get(uri: uri, param: parameters, header: headers) { error, data in
            if data != nil {
                // decoder
                let decoder: JSONDecoder = JSONDecoder()
                self.data = try? decoder.decode(Point.self, from: data!)
                self.point = 0
                
                for value in self.data!.data.score {
                    self.point += value.score
                }
                complition()
            }
            else {
                print(error! as AFError)
                self.present(self.alert, animated: true, completion: nil)
            }
        }
    }
    
    // 차트의 각도를 반환하는 함수
    private func newAngle(currentpoint: Double, maxpoint: Double) -> Double {
        return Double(360 * (point / maxpoint))
    }
    
    // 프로필 사진을 원형으로 처리하는 함수
    private func circleimage() {
        image.layer.cornerRadius = image.frame.height/2
        image.layer.borderWidth = 1
        image.clipsToBounds = true
        image.layer.borderColor = UIColor.clear.cgColor  //원형 이미지의 테두리 제거
    }
    
    // 차트의 애니메이션을 그리는 함수
    private func drawChart(_ point: Double) {
        circleChart.animate(fromAngle: 0, toAngle: newAngle(currentpoint: point, maxpoint: maxpoint), duration: 0.7, completion: nil)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

// 테이블뷰 처리
extension MainVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data?.data.score.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let score = data!.data.score
        let cell = (tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! customcell).then {
            $0.reasontext.text = score[indexPath.row].reason + " \(Int(score[indexPath.row].score))점"
            $0.datetext.text = String(score[indexPath.row].created_at.dropLast(14))
            $0.reasontext.textColor = bluecolor
        }
        if self.title == "벌점" {
            cell.reasontext.textColor = redcolor
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}
