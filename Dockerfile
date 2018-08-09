#FROM keymetrics/pm2:latest-alpine
FROM nvidia/cuda:9.1-cudnn7-devel-ubuntu16.04
#FROM valian/docker-python-opencv-ffmpeg:cuda-py3
#ENV NCCL_VERSION 2.2.12
VOLUME ["src/"]
# Bundle APP files
COPY src src/
COPY package.json .
COPY pm2.json .
#WORKDIR src

RUN echo -e "\n**********************\nNVIDIA Driver Version\n**********************\n" && \
	cat /proc/driver/nvidia/version && \
	echo -e "\n**********************\nCUDA Version\n**********************\n" && \
#	nvcc -V && \
	echo -e "\n\nBuilding your Deep Learning Docker Image...\n"

#Build opencv with contrib modules
RUN apt-get update && apt-get install libjpeg-dev libpango1.0-dev libgif-dev build-essential gcc g++ libxvidcore-dev libx264-dev libatlas-base-dev gfortran -y
RUN apt install build-essential cmake pkg-config unzip ffmpeg qtbase5-dev python-dev python3-dev python-numpy python3-numpy libhdf5-dev libgtk-3-dev libdc1394-22 libdc1394-22-dev libjpeg-dev libtiff5-dev libtesseract-dev -y
RUN apt install libavcodec-dev libavformat-dev libswscale-dev libxine2-dev libgstreamer-plugins-base1.0-0 libgstreamer-plugins-base1.0-dev libpng16-16 libpng-dev libv4l-dev libtbb-dev libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev libvorbis-dev libxvidcore-dev v4l-utils libleptonica-dev -y
RUN apt-get install git -y
COPY opencv opencv/
COPY opencv_contrib opencv_contrib/
RUN cd opencv && \
    mkdir build && cd build && \
    export LD_LIBRARY_PATH=/usr/local/cuda/lib && export PATH=$PATH:/usr/local/cuda/bin && \
    cmake -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_NVCUVID=ON -D FORCE_VTK=ON -D WITH_XINE=ON -D WITH_CUDA=ON -D WITH_OPENGL=ON -D WITH_TBB=ON -D WITH_OPENCL=ON -D CMAKE_BUILD_TYPE=RELEASE -D CUDA_NVCC_FLAGS="-D_FORCE_INLINES --expt-relaxed-constexpr" -D WITH_GDAL=ON -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules/ -D ENABLE_FAST_MATH=1 -D CUDA_FAST_MATH=1 -D WITH_CUBLAS=1 -D CXXFLAGS="-std=c++11" -DCMAKE_CXX_COMPILER=g++ -DCMAKE_C_COMPILER=gcc .. && \
    make -j1 && \
    make install && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf && cd .. && cd ..
    
RUN apt install libtesseract-dev git cmake build-essential libleptonica-dev liblog4cplus-dev libcurl3-dev libleptonica-dev libcurl4-openssl-dev liblog4cplus-dev beanstalkd openjdk-8-jdk -y
COPY openalpr openalpr/
RUN cd openalpr/src && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_INSTALL_SYSCONFDIR:PATH=/etc –DCOMPILE_GPU=1 -D WITH_GPU_DETECTOR=ON .. && \
    make && \
    make install && \
    cd .. && cd .. & cd ..

#RUN echo "mariadb-server mariadb-server/root_password password 1234" | debconf-set-selections && echo "mariadb-server mariadb-server/root_password_again password 1234" | debconf-set-selections && apt-get update && apt-get install -y --no-install-recommends python make g++ git ttf-freefont socat bash wget apt-utils mariadb-server && service mysql start && mysql -u root -p1234 -e "source /src/sql/user.sql" || true && mysql -u root -p1234 -e "source /src/sql/framework.sql" || true
RUN apt-get update && apt-get install -y sudo libcairo2-dev libjpeg8-dev libpango1.0-dev libgif-dev build-essential g++ wget
RUN wget https://deb.nodesource.com/setup_8.x && chmod +x setup_8.x && ./setup_8.x && sudo apt install nodejs -y && rm setup_8.x
#RUN apt-get install git && wget https://gitlab.com/Shinobi-Systems/Shinobi/raw/dev/INSTALL/opencv-cuda.sh && sh opencv-cuda.sh
#RUN sudo add-apt-repository ppa:jonathonf/ffmpeg-3 -y && sudo apt update -y && sudo apt install ffmpeg libav-tools x264 x265 -y
RUN npm install
#RUN npm install sqlite3
RUN npm install http-proxy
RUN npm install -g pm2
RUN export OPENCV4NODEJS_DISABLE_AUTOBUILD=1 && npm install opencv4nodejs moment express canvas@1.6 --unsafe-perm
RUN whereis pm2
WORKDIR src
#RUN cp /src/sql/shinobi.sample.sqlite /src/shinobi.sqlite
#RUN chmod 777 /src/dbdata/shinobi.sqlite 
#RUN wget https://raw.githubusercontent.com/ShinobiCCTV/Shinobi/dev/INSTALL/opencv-cuda.sh
#RUN bash opencv-cuda.sh
#RUN sh plugins/opencv/INSTALL.sh
#RUN node tools/modifyConfiguration.js databaseType=sqlite3 db='{"filename":"/src/shinobi.sqlite"}'
#RUN chmod 777 shinobi.sqlite
#WORKDIR /
# Show current folder structure in logs
#RUN ls -al -R
ENV HOME "src/"
WORKDIR /src/plugins/python-yolo
RUN sh INSTALL.sh
RUN echo $HOME
RUN pwd
CMD [ "pm2-runtime", "start", "shinobi-python-yolo.js" ]
