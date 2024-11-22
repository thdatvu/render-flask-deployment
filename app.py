from datetime import datetime
import os
import requests
import pyodbc
import flask
import json  
import logging
from Config import *
from SQLQuery import *
try:
    # kết nối
    conn = pyodbc.connect(con_str)
    print("Kết nối Thành công")
    app = flask.Flask(__name__)
    # GET: select, POST: insert, PUT: cập nhật dữ liệu, DELETE: xóa dữ liệu
    @app.route('/api/sanpham/getall', methods=['GET'])
    def getAllSanPham():
        try:
            cursor = conn.cursor()
            sql = SQLGETALL_SP
            cursor.execute(sql)
            results = [] # kết quả
            keys = []
            for i in cursor.description: # lấy các key
                keys.append(i[0])
            for i in cursor.fetchall(): # lấy tất cả bản ghi
                results.append(dict(zip(keys, i)))
            resp = flask.jsonify(results)
            resp.status_code = 200
            return resp
        except Exception as e:
            return flask.jsonify({"lỗi":e})
        
    @app.route('/api/khachhang/getall', methods=['GET'])
    def getAllKH():
        try:
            cursor = conn.cursor()
            sql = SQLGETALL_KH
            cursor.execute(sql)
            results = [] # kết quả
            keys = []
            for i in cursor.description: # lấy các key
                keys.append(i[0])
            for i in cursor.fetchall(): # lấy tất cả bản ghi
                results.append(dict(zip(keys, i)))
            resp = flask.jsonify(results)
            resp.status_code = 200
            return resp
        except Exception as e:
            return flask.jsonify({"lỗi":e})
    
    @app.route('/api/sanpham/getbyname/<ten>', methods=['GET'])
    def getByName(ten):
        try:
            cursor = conn.cursor()
            sql = "exec SearchSanPhamByName @TenSP = ?"  # Thay thế với tên thủ tục của bạn
            data = (ten,)  # Tham số truyền vào
            cursor.execute(sql, data)
            
            result = []
            keys = [column[0] for column in cursor.description]  # Lấy các key
            for row in cursor.fetchall():  # Lấy kết quả
                result.append(dict(zip(keys, row)))

            resp = flask.jsonify(result)  # Trả về kết quả
            resp.status_code = 200
            return resp
        except Exception as e:
            return flask.jsonify({"lỗi": str(e)}), 500  # Trả về lỗi nếu có
    
    @app.route('/api/sanpham/add', methods=['POST'])
    def insertSanPham():
        cursor = None  # Khởi tạo cursor là None để tránh lỗi UnboundLocalError
        try:
            # Lấy dữ liệu từ yêu cầu POST
            data = flask.request.get_json()
            # Kiểm tra dữ liệu đầu vào
            TenSP = data.get('TenSP')
            MoTa = data.get('MoTa')
            GiaBan = data.get('GiaBan')
            GiaNhap = data.get('GiaNhap')
            SLNhap = data.get('SL')
            MaDanhMuc = data.get('MaDanhMuc')
            TenFileAnh = data.get('AnhSanPham')

            if not all([TenSP, MoTa, GiaBan, GiaNhap, SLNhap, MaDanhMuc, TenFileAnh]):
                return flask.jsonify({"lỗi": "Thiếu thông tin sản phẩm"}), 400

            # Gọi procedure InsertNewSanPhamtoMenu
            cursor = conn.cursor()
            sql = "{CALL InsertNewSanPhamtoMenu(?, ?, ?, ?, ?, ?, ?)}"
            params = (TenSP, MoTa, GiaBan, GiaNhap, SLNhap, MaDanhMuc, TenFileAnh)
            cursor.execute(sql, params)
            conn.commit()
            
            return flask.jsonify({"thông báo": "Thêm sản phẩm thành công"}), 201
        except Exception as e:
            return flask.jsonify({"lỗi": str(e)}), 500
        finally:
            if cursor:  # Kiểm tra nếu cursor đã được khởi tạo thì đóng nó
                cursor.close()

    def get_image_data_from_url(image_url):
        try:
            # Tải ảnh từ URL
            response = requests.get(image_url)
            if response.status_code == 200:
                return response.content  # Trả về dữ liệu ảnh dưới dạng binary
            else:
                print(f"Không thể tải ảnh từ URL. Mã lỗi: {response.status_code}")
                return None
        except Exception as e:
            # In thông báo lỗi chi tiết
            print(f"Error: {str(e)}")
            return None
        
    @app.route('/api/update-san-pham', methods=['PUT'])
    def update_san_pham():
        try:
            # Lấy dữ liệu từ request JSON
            data = flask.request.get_json()

            # Lấy các tham số từ request
            MaSP = data.get('MaSP')
            TenSP = data.get('TenSP')
            MoTa = data.get('MoTa')
            GiaBan = data.get('GiaBan')
            GiaNhap = data.get('GiaNhap')
            MaDanhMuc = data.get('MaDanhMuc')
            SoLuong = data.get('SL')
            TenFileAnh = data.get('AnhSanPham')  # Nhận URL ảnh từ client

            # Kiểm tra xem các tham số bắt buộc có tồn tại không
            if not MaSP or not TenSP or not MoTa or not GiaBan or not GiaNhap or not SoLuong or not MaDanhMuc:
                return flask.jsonify({"status": "error", "message": "Thiếu thông tin bắt buộc"}), 400

            # Kết nối cơ sở dữ liệu
            conn = pyodbc.connect(con_str)
            cursor = conn.cursor()

            # Thực thi thủ tục UpdateSanPhamNew
            cursor.execute("""
                EXEC UpdateSanPhamNew @MaSP = ?, @TenSP = ?, @MoTa = ?, @GiaBan = ?, 
                    @GiaNhap = ?, @MaDanhMuc = ?, @SoLuong = ?, @FileAnh = ?
            """, MaSP, TenSP, MoTa, GiaBan, GiaNhap, MaDanhMuc, SoLuong, TenFileAnh)

            conn.commit()

            # Trả về kết quả thành công
            return flask.jsonify({
                "status": "success",
                "message": "Cập nhật sản phẩm thành công!"
            }), 200

        except Exception as e:
            # In lỗi chi tiết
            print(f"Lỗi chi tiết: {str(e)}")
            return flask.jsonify({"status": "error", "message": f"Lỗi: {str(e)}"}), 500

        finally:
            # Đảm bảo đóng kết nối và cursor
            if 'cursor' in locals():
                cursor.close()
            if 'conn' in locals():
                conn.close()

    
    @app.route('/api/sanpham/delete/<MaSP>', methods=['DELETE'])
    def deleteSanPham(MaSP):
        cursor = None
        try:
            # Kiểm tra xem MaSP có bị thiếu hay không
            if not MaSP:
                return flask.jsonify({"lỗi": "Thiếu mã sản phẩm"}), 400

            # Kết nối cơ sở dữ liệu và gọi procedure DeleteSanPham
            cursor = conn.cursor()
            sql = "{CALL DeleteSanPham(?)}"
            cursor.execute(sql, (MaSP,))
            
            # Commit nếu không có lỗi
            conn.commit()
            
            # Kiểm tra thông báo từ stored procedure (nếu có in ra)
            if cursor.rowcount == -1:  # Trong một số driver, rowcount = -1 nếu không thay đổi trực tiếp số dòng
                return flask.jsonify({"thông báo": "Xóa sản phẩm thành công hoặc đã được đánh dấu 'Deleted'."}), 200
            else:
                return flask.jsonify({"thông báo": "Xóa sản phẩm thành công"}), 200

        except Exception as e:
            conn.rollback()  # Rollback giao dịch nếu có lỗi
            print(f"Lỗi: {e}")  # Debug lỗi chi tiết trong console
            return flask.jsonify({"lỗi": f"Lỗi khi xóa sản phẩm: {str(e)}"}), 500

        finally:
            if cursor:
                cursor.close()  # Đảm bảo cursor được đóng


                
    # BAT DAU API DANH MUC
    @app.route('/api/danhmuc/getall', methods=['GET'])
    def getAllDanhMuc():
        try:
            cursor = conn.cursor()
            sql = SQLGETALL_DM
            cursor.execute(sql)
            results = [] # kết quả
            keys = []
            for i in cursor.description: # lấy các key
                keys.append(i[0])
            for i in cursor.fetchall(): # lấy tất cả bản ghi
                results.append(dict(zip(keys, i)))
            resp = flask.jsonify(results)
            resp.status_code = 200
            return resp
        except Exception as e:
            return flask.jsonify({"lỗi":e})
    #Lay dan pham theo danh muc
    @app.route('/api/sanpham/danhmuc', methods=['GET'])
    def getSanPhamByMaDanhMuc():
        try:
            # Lấy tham số MaDanhMuc từ query string
            MaDanhMuc = flask.request.args.get('MaDanhMuc')

            if not MaDanhMuc:
                return flask.jsonify({"lỗi": "Thiếu tham số MaDanhMuc"}), 400

            # Thực thi Stored Procedure trong SQL Server
            cursor = conn.cursor()
            # Gọi stored procedure GetSanPhamByMaDanhMuc với tham số MaDanhMuc
            cursor.execute("{CALL GetSanPhamByMaDanhMuc (?)}", MaDanhMuc)
            
            # Lấy kết quả
            rows = cursor.fetchall()

            # Kiểm tra nếu không có sản phẩm
            if not rows:
                return flask.jsonify({"lỗi": "Không tìm thấy sản phẩm"}), 404

            # Chuyển đổi dữ liệu thành JSON
            products = []
            for row in rows:
                product = {
                    "MaSP": row.MaSP,
                    "TenSP": row.TenSP,
                    "MoTa": row.MoTa,
                    "GiaBan": row.GiaBan,
                    "GiaNhap": row.GiaNhap,
                    "SL": row.SL,
                    "AnhSanPham": row.AnhSanPham,
                    "MaDanhMuc": row.MaDanhMuc
                }
                products.append(product)

            return flask.jsonify(products), 200

        except Exception as e:
            return flask.jsonify({"lỗi": str(e)}), 500
        finally:
            cursor.close()
        #KET THUC API DANH MUC
        #BAT DAU API USER
    @app.route('/api/user/add', methods=['POST'])
    def addUser():
        try:
            # Lấy dữ liệu từ yêu cầu POST
            data = flask.request.get_json()
            # Kiểm tra dữ liệu đầu vào
            SĐT = data.get('SĐT')  # Số điện thoại
            Email = data.get('Email')  # Email
            Password = data.get('PassWord')  # Mật khẩu
            Type = data.get('Type')

            if not all([SĐT, Email, Password, Type]):
                return flask.jsonify({"lỗi": "Thiếu thông tin người dùng"}), 400

            # Kiểm tra Type: 1 là khách hàng, 0 là nhân viên
            if Type not in [0, 1]:
                return flask.jsonify({"lỗi": "Loại người dùng không hợp lệ"}), 400

            # Gọi procedure thêm người dùng vào bảng tbUser
            cursor = conn.cursor()
            sql = "{CALL proc_AddUser(?, ?, ?, ?)}"  # Stored procedure thêm người dùng
            params = (SĐT, Email, Password, Type)
            cursor.execute(sql, params)
            conn.commit()
            
            return flask.jsonify({"thông báo": "Thêm người dùng thành công"}), 201
        except Exception as e:
            return flask.jsonify({"lỗi": str(e)}), 500
        finally:
            if cursor:
                cursor.close()

    @app.route('/api/user/getall', methods=['GET'])
    def getAllUser():
        try:
            cursor = conn.cursor()
            sql = SQLGETALL_User
            cursor.execute(sql)
            results = [] # kết quả
            keys = []
            for i in cursor.description: # lấy các key
                keys.append(i[0])
            for i in cursor.fetchall(): # lấy tất cả bản ghi
                results.append(dict(zip(keys, i)))
            resp = flask.jsonify(results)
            resp.status_code = 200
            return resp
        except Exception as e:
            return flask.jsonify({"lỗi":e})
    @app.route('/api/user/login', methods=['POST'])
    def login():
        try:
            # Lấy dữ liệu từ request (email hoặc số điện thoại và mật khẩu)
            data = flask.request.get_json()
            email_or_phone = data.get('EmailOrPhone')  # Dữ liệu có thể là email hoặc số điện thoại
            password = data.get('PassWord')

            # Kiểm tra dữ liệu nhập vào
            if not email_or_phone or not password:
                return flask.jsonify({"status": "error", "message": "Email/SĐT và mật khẩu là bắt buộc"}), 400

            # Kết nối cơ sở dữ liệu và truy vấn người dùng với email hoặc số điện thoại và mật khẩu
            cursor = conn.cursor()

            # Truy vấn tìm kiếm theo email hoặc số điện thoại
            sql = SQL_UserLogin
            cursor.execute(sql, (email_or_phone, email_or_phone, password))

            # Lấy kết quả trả về từ cơ sở dữ liệu
            user = cursor.fetchone()
            
            if user:
                # Nếu tìm thấy người dùng, trả về thông tin người dùng
                keys = [description[0] for description in cursor.description]
                user_dict = dict(zip(keys, user))
                return flask.jsonify({"status": "success", "message": "Đăng nhập thành công", "user": user_dict}), 200
            else:
                # Nếu không tìm thấy người dùng, trả về lỗi
                return flask.jsonify({"status": "error", "message": "Sai email, số điện thoại hoặc mật khẩu"}), 401

        except Exception as e:
            return flask.jsonify({"status": "error", "message": str(e)}), 500

    #KET THUC API USER
    #API HOA DON NHAP
    @app.route('/api/get-hoa-don-nhap', methods=['GET'])
    def get_hoa_don_nhap():
        try:
            # Kết nối cơ sở dữ liệu
            conn = pyodbc.connect(con_str)
            cursor = conn.cursor()

            # Truy vấn dữ liệu từ bảng tbHoaDonNhap
            cursor.execute("SELECT * FROM tbHoaDonNhap")
            rows = cursor.fetchall()

            # Chuyển dữ liệu thành danh sách các từ điển
            columns = [column[0] for column in cursor.description]  # Lấy tên các cột
            result = [dict(zip(columns, row)) for row in rows]  # Chuyển từng dòng thành dictionary

            # Trả về dữ liệu dưới dạng JSON
            return flask.jsonify({
                "status": "success",
                "data": result
            }), 200

        except Exception as e:
            # Log lỗi chi tiết
            return flask.jsonify({"status": "error", "message": f"Lỗi: {str(e)}"}), 500

        finally:
            # Đảm bảo đóng kết nối và cursor
            if 'cursor' in locals():
                cursor.close()
            if 'conn' in locals():
                conn.close()

    @app.route('/api/create-hoa-don-nhap', methods=['POST'])
    def create_hoa_don_nhap():
        try:
            # Lấy dữ liệu từ request
            data = flask.request.get_json()
            ma_nv = data.get('MaNV')  # Mã nhân viên
            ma_ncc = data.get('MaNCC')  # Mã nhà cung cấp
            ngay_lap = data.get('NgayLap')  # Ngày lập hóa đơn
            danh_sach_san_pham = data.get('DanhSachSanPham')  # Danh sách sản phẩm (list)

            # Kiểm tra nếu có thiếu thông tin
            if not ma_nv or not ma_ncc or not ngay_lap or not danh_sach_san_pham:
                return flask.jsonify({"status": "error", "message": "Thiếu thông tin bắt buộc"}), 400

            # Kết nối cơ sở dữ liệu
            conn = pyodbc.connect(con_str)  # Thay vì gọi connect_db()
            cursor = conn.cursor()

            # Xóa bảng tạm nếu đã tồn tại
            cursor.execute("DROP TABLE IF EXISTS TempDanhSachSanPham;")
            conn.commit()

            # Tạo bảng tạm `TempDanhSachSanPham`
            cursor.execute("""
            CREATE TABLE TempDanhSachSanPham (
                TenSP NVARCHAR(100),
                GiaNhap DECIMAL(18, 2),
                SoLuongNhap INT
            );
            """)
            conn.commit()

            # Chèn danh sách sản phẩm vào bảng tạm
            for sp in danh_sach_san_pham:
                cursor.execute("""
                INSERT INTO TempDanhSachSanPham (TenSP, GiaNhap, SoLuongNhap)
                VALUES (?, ?, ?);
                """, sp.get('TenSP'), sp.get('GiaNhap'), sp.get('SoLuongNhap'))
            conn.commit()

            # Gọi stored procedure `CreateHoaDonNhap`
            cursor.execute("""
            EXEC CreateHoaDonNhap @MaNV = ?, @MaNCC = ?, @NgayLap = ?;
            """, ma_nv, ma_ncc, ngay_lap)
            conn.commit()

            # Truy vấn để lấy thông tin hóa đơn vừa tạo
            cursor.execute("""
            SELECT TenSP, GiaNhap, SoLuongNhap FROM TempDanhSachSanPham;
            """)
            products = cursor.fetchall()

            # Chuyển kết quả từ cursor.fetchall() thành dạng JSON
            products_data = [{"TenSP": product[0], "GiaNhap": product[1], "SoLuongNhap": product[2]} for product in products]

            # Tính tổng giá trị hóa đơn (nếu cần)
            total_value = sum([product[1] * product[2] for product in products])

            # Xóa bảng tạm sau khi thực hiện xong
            cursor.execute("DROP TABLE TempDanhSachSanPham;")
            conn.commit()

            # Trả về kết quả chi tiết
            return flask.jsonify({
                "status": "success",
                "message": "Hóa đơn nhập được tạo thành công!",
                "ma_nv": ma_nv,
                "ma_ncc": ma_ncc,
                "ngay_lap": ngay_lap,
                "products": products_data,
                "total_value": total_value
            }), 201

        except Exception as e:
            return flask.jsonify({"status": "error", "message": str(e)}), 500

        finally:
            if 'cursor' in locals():
                cursor.close()
            if 'conn' in locals():
                conn.close()
                
    
    @app.route('/api/update-hoa-don-nhap', methods=['POST'])
    def update_hoa_don_nhap():
        try:
            # Lấy dữ liệu từ request
            data = flask.request.get_json()
            ma_hdn = data.get('MaHDN')  # Mã hóa đơn cần cập nhật
            ma_nv = data.get('MaNV')    # Mã nhân viên
            ma_ncc = data.get('MaNCC')  # Mã nhà cung cấp
            ngay_lap = data.get('NgayLap')  # Ngày lập mới
            danh_sach_san_pham = data.get('DanhSachSanPham')  # Danh sách sản phẩm (list)

            # Kiểm tra nếu có thiếu thông tin
            if not ma_hdn or not ma_nv or not ma_ncc or not ngay_lap or not danh_sach_san_pham:
                return flask.jsonify({"status": "error", "message": "Thiếu thông tin bắt buộc"}), 400

            # Kết nối cơ sở dữ liệu
            conn = pyodbc.connect(con_str)
            cursor = conn.cursor()

            # Xóa bảng tạm nếu đã tồn tại
            cursor.execute("DROP TABLE IF EXISTS TempDanhSachSanPham;")
            conn.commit()

            # Tạo bảng tạm `TempDanhSachSanPham`
            cursor.execute("""
            CREATE TABLE TempDanhSachSanPham (
                TenSP NVARCHAR(100),
                GiaNhap DECIMAL(18, 2),
                SoLuongNhap INT
            );
            """)
            conn.commit()

            # Chèn danh sách sản phẩm vào bảng tạm
            for sp in danh_sach_san_pham:
                cursor.execute("""
                INSERT INTO TempDanhSachSanPham (TenSP, GiaNhap, SoLuongNhap)
                VALUES (?, ?, ?);
                """, sp.get('TenSP'), sp.get('GiaNhap'), sp.get('SoLuongNhap'))
            conn.commit()

            # Gọi thủ tục `UpdateHoaDonNhap`
            cursor.execute("""
            EXEC UpdateHoaDonNhap @MaHDN = ?, @MaNV = ?, @MaNCC = ?, @NgayLap = ?;
            """, ma_hdn, ma_nv, ma_ncc, ngay_lap)
            conn.commit()

            # Trả về kết quả thành công
            return flask.jsonify({
                "status": "success",
                "message": "Hóa đơn nhập đã được cập nhật thành công!",
                "MaHDN": ma_hdn,
                "MaNV": ma_nv,
                "MaNCC": ma_ncc,
                "NgayLap": ngay_lap,
                "DanhSachSanPham": danh_sach_san_pham
            }), 200

        except Exception as e:
            return flask.jsonify({"status": "error", "message": str(e)}), 500

        finally:
            if 'cursor' in locals():
                cursor.close()
            if 'conn' in locals():
                conn.close()
    @app.route('/api/delete-hoa-don-nhap', methods=['DELETE'])
    def delete_hoa_don_nhap():
        try:
            # Lấy dữ liệu từ request
            data = flask.request.get_json()
            ma_hdn = data.get('MaHDN')  # Mã hóa đơn cần xóa

            # Kiểm tra nếu thiếu Mã hóa đơn
            if not ma_hdn:
                return flask.jsonify({"status": "error", "message": "Thiếu thông tin Mã hóa đơn"}), 400

            # Kết nối cơ sở dữ liệu
            conn = pyodbc.connect(con_str)  # Thay vì gọi connect_db()
            cursor = conn.cursor()

            # Gọi stored procedure `DeleteHoaDonNhap` để xóa hóa đơn
            cursor.execute("""
                EXEC DeleteHoaDonNhap @MaHDN = ?;
            """, ma_hdn)
            conn.commit()

            return flask.jsonify({"status": "success", "message": f"Hóa đơn nhập {ma_hdn} đã được xóa thành công!"}), 200

        except Exception as e:
            return flask.jsonify({"status": "error", "message": str(e)}), 500

        finally:
            if 'cursor' in locals():
                cursor.close()
            if 'conn' in locals():
                conn.close()
        #HET HOA DON NHAP
        #BAT DAU HOA HON BAN
    @app.route('/api/get-don-hang', methods=['GET'])
    def get_don_hang():
        try:
            # Kết nối cơ sở dữ liệu
            conn = pyodbc.connect(con_str)
            cursor = conn.cursor()

            # Thực thi câu lệnh SQL để lấy dữ liệu
            cursor.execute("SELECT * FROM tbDonHang")
            rows = cursor.fetchall()

            # Lấy tên các cột
            columns = [column[0] for column in cursor.description]

            # Chuyển đổi kết quả truy vấn thành danh sách từ điển
            result = [dict(zip(columns, row)) for row in rows]

            # Trả về kết quả dưới dạng JSON
            return flask.jsonify({
                "status": "success",
                "data": result
            }), 200

        except Exception as e:
            # Trả về thông báo lỗi nếu có
            return flask.jsonify({"status": "error", "message": f"Lỗi: {str(e)}"}), 500

        finally:
            # Đảm bảo đóng kết nối
            if 'cursor' in locals():
                cursor.close()
            if 'conn' in locals():
                conn.close()
    
    @app.route('/api/create-don-hang', methods=['POST'])
    def create_don_hang():
        try:
            # Lấy dữ liệu từ request
            data = flask.request.get_json()

            # Lấy các tham số cần thiết từ request
            ma_kh = data.get('MaKH')  # Mã khách hàng
            ma_nv = data.get('MaNV')  # Mã nhân viên
            ngay_lap = data.get('NgayLap')  # Ngày lập đơn hàng
            trang_thai = data.get('TrangThai')  # Trạng thái đơn hàng
            phuong_thuc_thanh_toan = data.get('PhuongThucThanhToan')  # Phương thức thanh toán

            # Kiểm tra xem có thiếu tham số nào không
            if not all([ma_kh, ma_nv, ngay_lap, trang_thai, phuong_thuc_thanh_toan]):
                return flask.jsonify({"status": "error", "message": "Thiếu thông tin bắt buộc"}), 400

            # Kết nối cơ sở dữ liệu
            conn = pyodbc.connect(con_str)
            cursor = conn.cursor()

            # Thực thi thủ tục CreateDonHang
            cursor.execute("""
                EXEC CreateDonHang 
                    @MAKH = ?, 
                    @MaNV = ?, 
                    @NgayLap = ?, 
                    @TrangThai = ?, 
                    @PhuongThucThanhToan = ?
            """, ma_kh, ma_nv, ngay_lap, trang_thai, phuong_thuc_thanh_toan)

            conn.commit()

            # Trả về kết quả thành công
            return flask.jsonify({
                "status": "success",
                "message": "Đơn hàng đã được tạo thành công!"
            }), 200

        except Exception as e:
            # Log lỗi chi tiết
            return flask.jsonify({"status": "error", "message": f"Lỗi: {str(e)}"}), 500

        finally:
            # Đảm bảo đóng kết nối và cursor
            if 'cursor' in locals():
                cursor.close()
            if 'conn' in locals():
                conn.close()



    @app.route('/api/delete-don-hang/<ma_hd>', methods=['DELETE'])
    def delete_don_hang(ma_hd):
        try:
            # Kiểm tra xem có thiếu mã đơn hàng không
            if not ma_hd:
                return flask.jsonify({"status": "error", "message": "Thiếu Mã Đơn Hàng"}), 400

            # Kết nối cơ sở dữ liệu
            conn = pyodbc.connect(con_str)
            cursor = conn.cursor()

            # Thực thi thủ tục DeleteDonHang
            cursor.execute("""
                EXEC DeleteDonHang @MaHD = ?
            """, ma_hd)

            conn.commit()

            # Trả về kết quả thành công
            return flask.jsonify({
                "status": "success",
                "message": "Đơn hàng và các chi tiết liên quan đã được xóa thành công!"
            }), 200

        except Exception as e:
            # Log lỗi chi tiết
            return flask.jsonify({"status": "error", "message": f"Lỗi: {str(e)}"}), 500

        finally:
            # Đảm bảo đóng kết nối và cursor
            if 'cursor' in locals():
                cursor.close()
            if 'conn' in locals():
                conn.close()
    #LAY GIO HANG
    @app.route('/api/giohang', methods=['GET'])
    def get_gio_hang_by_ma_khach_hang():
        try:
            # Lấy tham số MaKH từ query string
            MaKH = flask.request.args.get('MaKH')

            if not MaKH:
                return flask.jsonify({"lỗi": "Thiếu tham số MaKH"}), 400

            # Thực thi Stored Procedure trong SQL Server
            cursor = conn.cursor()
            # Gọi stored procedure LaySanPhamGioHangTheoMaKH với tham số MaKH
            cursor.execute("{CALL LaySanPhamGioHangTheoMaKH (?)}", MaKH)

            # Lấy kết quả
            rows = cursor.fetchall()

            # Kiểm tra nếu không có sản phẩm trong giỏ hàng
            if not rows:
                return flask.jsonify({"lỗi": "Không tìm thấy sản phẩm trong giỏ hàng"}), 404

            # Chuyển đổi dữ liệu thành JSON
            cart_items = []
            for row in rows:
                item = {
                    "MaDonHang": row.MaDonHang,
                    "MaKhachHang": row.MaKhachHang,
                    "TenKhachHang": row.TenKhachHang,
                    "MaSanPham": row.MaSanPham,
                    "TenSanPham": row.TenSanPham,
                    "MoTaSanPham": row.MoTaSanPham,
                    "GiaBan": row.GiaBan,
                    "SoLuong": row.SoLuong,
                    "AnhSanPham": row.AnhSanPham,
                    "GiamGia": row.GiamGia,
                    "ThanhTien": row.ThanhTien,
                    "NgayTaoGioHang": row.NgayTaoGioHang
                }
                cart_items.append(item)

            return flask.jsonify(cart_items), 200

        except Exception as e:
            return flask.jsonify({"lỗi": str(e)}), 500

        finally:
            cursor.close() # Đảm bảo cursor được đóng
    @app.route('/api/giohang/add', methods=['POST'])
    def them_san_pham_vao_gio_hang():
        try:
            # Lấy dữ liệu từ request
            data = flask.request.get_json()
            MaKH = data.get('MaKH')
            MaSP = data.get('MaSP')
            SoLuong = data.get('SoLuong')

            # Kiểm tra tham số đầu vào
            if not MaKH or not MaSP or SoLuong is None:
                return flask.jsonify({"error": "Thiếu tham số MaKH, MaSP hoặc SoLuong"}), 400

            # Thực thi stored procedure
            cursor = conn.cursor()
            cursor.execute("{CALL ThemSanPhamVaoGioHang (?, ?, ?)}", (MaKH, MaSP, SoLuong))
            conn.commit()

            # Trả về phản hồi thành công
            return flask.jsonify({"message": "Sản phẩm đã được thêm vào giỏ hàng thành công"}), 200

        except Exception as e:
            # Xử lý lỗi
            return flask.jsonify({"error": str(e)}), 500

        finally:
            cursor.close()
            
    #XOA SP khoi gio hang
    @app.route('/giohang/delete/<MaKH>/<MaSP>', methods=['DELETE'])
    def deleteSP(MaKH, MaSP):
        cursor = None
        try:
            # Kiểm tra xem MaKH và MaSP có bị thiếu hay không
            if not MaKH or not MaSP:
                return flask.jsonify({"lỗi": "Thiếu mã khách hàng hoặc mã sản phẩm"}), 400

            # Kết nối cơ sở dữ liệu và gọi procedure XoaSanPhamKhoiGioHang
            cursor = conn.cursor()

            # Thực thi stored procedure XoaSanPhamKhoiGioHang với MaKH và MaSP
            sql = "{CALL XoaSanPhamKhoiGioHang(?, ?)}"
            cursor.execute(sql, (MaKH, MaSP))

            # Commit nếu không có lỗi
            conn.commit()

            # Kiểm tra xem sản phẩm đã được xóa hay không
            if cursor.rowcount == 0:  # Nếu không có thay đổi, tức là không tìm thấy sản phẩm trong giỏ hàng
                return flask.jsonify({"thông báo": "Sản phẩm không có trong giỏ hàng"}), 404
            else:
                return flask.jsonify({"thông báo": "Xóa sản phẩm khỏi giỏ hàng thành công"}), 200

        except Exception as e:
            conn.rollback()  # Rollback giao dịch nếu có lỗi
            print(f"Lỗi: {e}")  # Debug lỗi chi tiết trong console
            return flask.jsonify({"lỗi": f"Lỗi khi xóa sản phẩm: {str(e)}"}), 500

        finally:
            if cursor:
                cursor.close() 
    #CAP NHAT
    @app.route('/api/giohang/update', methods=['PUT'])
    def cap_nhat_so_luong_san_pham():
        try:
            # Lấy dữ liệu từ request
            data = flask.request.get_json()
            MaKH = data.get('MaKH')
            MaSP = data.get('MaSP')
            SoLuong = data.get('SoLuong')

            # Kiểm tra tham số đầu vào
            if not MaKH or not MaSP or SoLuong is None:
                return flask.jsonify({"error": "Thiếu tham số MaKH, MaSP hoặc SoLuong"}), 400

            # Thực thi stored procedure
            cursor = conn.cursor()
            cursor.execute("{CALL CapNhatSoLuongSanPhamTrongGioHang (?, ?, ?)}", (MaKH, MaSP, SoLuong))
            conn.commit()

            # Trả về phản hồi thành công
            return flask.jsonify({"message": "Số lượng sản phẩm đã được cập nhật thành công"}), 200

        except Exception as e:
            # Xử lý lỗi
            return flask.jsonify({"error": str(e)}), 500

        finally:
            cursor.close()

    #LAY DON HANG
    @app.route('/api/get-doanh-thu-theo-ngay', methods=['POST'])
    def get_doanh_thu_theo_ngay():
        try:
            # Lấy dữ liệu từ request
            data = flask.request.get_json()

            # Lấy tham số Ngày cần tính doanh thu
            ngay = data.get('Ngay')  # Ngày cần tính doanh thu

            # Kiểm tra xem có thiếu tham số nào không
            if not ngay:
                return flask.jsonify({"status": "error", "message": "Thiếu Ngày"}), 400

            # Kết nối cơ sở dữ liệu
            conn = pyodbc.connect(con_str)
            cursor = conn.cursor()

            # Thực thi thủ tục GetDoanhThuTheoNgay
            cursor.execute("EXEC GetDoanhThuTheoNgay @Ngay = ?", ngay)

            # Lấy kết quả
            result = cursor.fetchone()
            if result:
                doanh_thu = result[1]  # Lấy tổng doanh thu
            else:
                doanh_thu = 0

            # Trả về kết quả
            return flask.jsonify({
                "status": "success",
                "Ngay": ngay,
                "TongDoanhThu": doanh_thu
            }), 200

        except Exception as e:
            # Log lỗi chi tiết
            return flask.jsonify({"status": "error", "message": f"Lỗi: {str(e)}"}), 500

        finally:
            # Đảm bảo đóng kết nối và cursor
            if 'cursor' in locals():
                cursor.close()
            if 'conn' in locals():
                conn.close()
                
    @app.route('/api/get-doanh-thu-theo-thang', methods=['POST'])
    def get_doanh_thu_theo_thang():
        try:
            # Lấy dữ liệu từ request
            data = flask.request.get_json()

            # Lấy tham số Tháng và Năm cần tính doanh thu
            thang = data.get('Thang')  # Tháng cần tính doanh thu
            nam = data.get('Nam')      # Năm cần tính doanh thu

            # Kiểm tra xem có thiếu tham số nào không
            if not thang or not nam:
                return flask.jsonify({"status": "error", "message": "Thiếu Tháng hoặc Năm"}), 400

            # Kết nối cơ sở dữ liệu
            conn = pyodbc.connect(con_str)
            cursor = conn.cursor()

            # Thực thi thủ tục GetDoanhThuTheoThang
            cursor.execute("EXEC GetDoanhThuTheoThang @Thang = ?, @Nam = ?", thang, nam)

            # Lấy kết quả
            result = cursor.fetchone()
            if result:
                doanh_thu = result[2]  # Lấy tổng doanh thu
            else:
                doanh_thu = 0

            # Trả về kết quả
            return flask.jsonify({
                "status": "success",
                "Thang": thang,
                "Nam": nam,
                "TongDoanhThu": doanh_thu
            }), 200

        except Exception as e:
            # Log lỗi chi tiết
            return flask.jsonify({"status": "error", "message": f"Lỗi: {str(e)}"}), 500

        finally:
            # Đảm bảo đóng kết nối và cursor
            if 'cursor' in locals():
                cursor.close()
            if 'conn' in locals():
                conn.close()
                
    @app.route('/api/get-doanh-thu-theo-nam', methods=['POST'])
    def get_doanh_thu_theo_nam():
        try:
            # Lấy dữ liệu từ request
            data = flask.request.get_json()

            # Lấy tham số Năm cần tính doanh thu
            nam = data.get('Nam')  # Năm cần tính doanh thu

            # Kiểm tra xem có thiếu tham số nào không
            if not nam:
                return flask.jsonify({"status": "error", "message": "Thiếu Năm"}), 400

            # Kết nối cơ sở dữ liệu
            conn = pyodbc.connect(con_str)
            cursor = conn.cursor()

            # Thực thi thủ tục GetDoanhThuTheoNam
            cursor.execute("EXEC GetDoanhThuTheoNam @Nam = ?", nam)

            # Lấy kết quả
            result = cursor.fetchone()
            if result:
                doanh_thu = result[1]  # Lấy tổng doanh thu
            else:
                doanh_thu = 0

            # Trả về kết quả
            return flask.jsonify({
                "status": "success",
                "Nam": nam,
                "TongDoanhThu": doanh_thu
            }), 200

        except Exception as e:
            # Log lỗi chi tiết
            return flask.jsonify({"status": "error", "message": f"Lỗi: {str(e)}"}), 500

        finally:
            # Đảm bảo đóng kết nối và cursor
            if 'cursor' in locals():
                cursor.close()
            if 'conn' in locals():
                conn.close()

    if __name__ == "__main__":
        port = int(os.getenv("PORT", 5000))  # Lấy PORT từ biến môi trường, mặc định là 5000 nếu không có
        app.run(debug=True, host="0.0.0.0", port=port)
except:
    print("Lỗi")

    
    
    
    

