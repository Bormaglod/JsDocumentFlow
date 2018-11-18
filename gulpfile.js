'use strict';

var gulp = require('gulp'),
    watch = require('gulp-watch'),
    prefixer = require('gulp-autoprefixer'),
    uglify = require('gulp-uglify-es').default,
    sass = require('gulp-sass'),
    sourcemaps = require('gulp-sourcemaps'),
    rigger = require('gulp-rigger'),
    cssmin = require('gulp-minify-css'),
    imagemin = require('gulp-imagemin'),
    pngquant = require('imagemin-pngquant'),
    gutil = require('gulp-util'),
    rimraf = require('rimraf');

var path = {
    build: { //Тут мы укажем куда складывать готовые после сборки файлы
        html: 'build/',
        js: 'build/js/',
        css: 'build/css/',
        img: 'build/img/',
        fonts: 'build/webfonts/',
        phplib: 'build/lib/',
	cssimg: 'build/css/images'
    },
    src: { //Пути откуда брать исходники
        html: ['src/*.html', 'src/*.php'], //Синтаксис src/*.html говорит gulp что мы хотим взять все файлы с расширением .html
        js: 'src/js/main.js',//В стилях и скриптах нам понадобятся только main файлы
        style: 'src/style/main.scss',
        img: 'src/img/**/*.*', //Синтаксис img/**/*.* означает - взять все файлы всех расширений из папки и из вложенных каталогов
        fonts: ['src/fonts/**/*.*', 'node_modules/@fortawesome/fontawesome-free/webfonts/*'],
        phplib: 'src/lib/**/*.php',
	styleimg: 'libs/jqwidgets/jqwidgets/styles/images/**/*'
    },
    watch: { //Тут мы укажем, за изменением каких файлов мы хотим наблюдать
        html: 'src/**/*.html',
        php: 'src/**/*.php',
        js: 'src/js/**/*.js',
        style: 'src/style/**/*.scss',
        img: 'src/img/**/*.*',
        fonts: 'src/fonts/**/*.*'
    },
    clean: './build'
};

gulp.task('html:build', function (done) {
    gulp.src(path.src.html) //Выберем файлы по нужному пути
        .pipe(rigger()) //Прогоним через rigger
        .pipe(gulp.dest(path.build.html)); //Выплюнем их в папку build
    
    gulp.src(path.src.phplib) 
        .pipe(rigger()) 
        .pipe(gulp.dest(path.build.phplib)); //Выплюнем их в папку build
    
    done();
});

gulp.task('js:build', function (done) {
    gulp.src(path.src.js) //Найдем наш main файл
        .pipe(rigger()) //Прогоним через rigger
        //.pipe(sourcemaps.init()) //Инициализируем sourcemap
        .pipe(uglify()) //Сожмем наш js
        .on('error', function (err) { gutil.log(gutil.colors.red('[Error]'), err.toString()); })
        //.pipe(sourcemaps.write()) //Пропишем карты
        .pipe(gulp.dest(path.build.js)); //Выплюнем готовый файл в build
    
    done();
});

gulp.task('style:build', function (done) {
    gulp.src(path.src.style) //Выберем наш main.scss
        //.pipe(sourcemaps.init()) //То же самое что и с js
        .pipe(sass()) //Скомпилируем
        .pipe(prefixer()) //Добавим вендорные префиксы
        .pipe(cssmin({keepSpecialComments: 0, rebase: false})) //Сожмем
        //.pipe(sourcemaps.write())
        .pipe(gulp.dest(path.build.css)); //И в build

    done();
});

gulp.task('image:build', function (done) {
    gulp.src(path.src.img) //Выберем наши картинки
        .pipe(imagemin({ //Сожмем их
            progressive: true,
            svgoPlugins: [{removeViewBox: false}],
            use: [pngquant()],
            interlaced: true
        }))
        .pipe(gulp.dest(path.build.img)); //И бросим в build

    gulp.src(path.src.styleimg) //Выберем наши картинки
        .pipe(gulp.dest(path.build.cssimg)); //И бросим в build

    done();
});

gulp.task('fonts:build', function(done) {
    gulp.src(path.src.fonts)
        .pipe(gulp.dest(path.build.fonts));
    
    done();
});

gulp.task('build', gulp.series([
    'html:build',
    'js:build',
    'style:build',
    'fonts:build',
    'image:build'
]));

gulp.task('watch', function(){
    watch([path.watch.html, path.watch.php], function(event, cb) {
        gulp.series('html:build');
    });
    watch([path.watch.style], function(event, cb) {
        gulp.series('style:build');
    });
    watch([path.watch.js], function(event, cb) {
        gulp.series('js:build');
    });
    watch([path.watch.img], function(event, cb) {
        gulp.series('image:build');
    });
    watch([path.watch.fonts], function(event, cb) {
        gulp.series('fonts:build');
    });
});

gulp.task('clean', function (cb) {
    rimraf(path.clean, cb);
});

gulp.task('default', gulp.series(['build', 'watch']));
