FROM ubuntu:xenial

ARG VNC_PASSWORD=secret
ENV VNC_PASSWORD=${VNC_PASSWORD} \
    WSPC=/root/catkin_ws \
    DEBIAN_FRONTEND=noninteractive
WORKDIR /root

# Allow universe and multiverse repos
RUN apt-get update; apt-get install -y software-properties-common wget; \
    apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116; \
    echo "deb http://packages.ros.org/ros/ubuntu xenial main" >/etc/apt/sources.list.d/ros-latest.list; \
    wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add -; \
    echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable xenial main" >/etc/apt/sources.list.d/gazebo-stable.list; \
    add-apt-repository "deb http://us.archive.ubuntu.com/ubuntu/ xenial restricted universe multiverse"; \
    add-apt-repository "deb http://us.archive.ubuntu.com/ubuntu/ xenial-updates restricted universe multiverse";

# Install dependencies
RUN apt-get update; apt-get install -y \
    dbus-x11 x11vnc xvfb supervisor \
    dwm suckless-tools stterm \
    ros-lunar-desktop \
    gazebo9 libgazebo9-dev \
    ros-lunar-gazebo9-* \
    ros-lunar-joystick-drivers ros-lunar-geographic-msgs \
    python-rosdep python-rosinstall python-rosinstall-generator python-wstool build-essential; \ 
    mkdir -p /etc/supervisor/conf.d; \
    x11vnc -storepasswd $VNC_PASSWORD /etc/vncsecret; \
    chmod 444 /etc/vncsecret; 

#    apt-get autoclean; \
#    apt-get autoremove; \
#    rm -rf /var/lib/apt/lists/*; 

COPY supervisord.conf /etc/supervisor/conf.d
EXPOSE 5900
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]

# Download UUV (todo as non-root)
RUN mkdir -p ${WSPC}/src; cd ${WSPC}; \
    . /opt/ros/lunar/setup.sh; . /usr/share/gazebo-9/setup.sh; \
    rosdep init; rosdep update; \
    catkin_make; . ${WSPC}/devel/setup.sh; \
    git clone https://github.com/uuvsimulator/uuv_simulator.git src/uuv_simulator; \
    rosinstall src /opt/ros/lunar https://raw.githubusercontent.com/uuvsimulator/uuv_simulator/master/ros_lunar.rosinstall; \
    rosdep install --from-paths src --ignore-src --rosdistro=lunar -y --skip-keys "gazebo gazebo_msgs gazebo_plugins gazebo_ros gazebo_ros_control gazebo_ros_pkgs"; \
    . ${WSPC}/src/setup.sh; \
    cd ${WSPC}; catkin_make install;


